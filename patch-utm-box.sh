#!/usr/bin/env bash
# patch-utm-box.sh
#
# Patches the "utm/ubuntu-24.04" Vagrant box to enable Apple's
# Virtualization.framework backend and nested virtualization, then
# registers the result as "boxes/ubuntu-24-04" — the box name
# already expected by your Vagrantfile.
#
# Requirements: vagrant, python3 (ships with macOS), tar, find
# Run on: macOS (Apple Silicon) with UTM installed

# ── Configuration ────────────────────────────────────────────────────────────
SOURCE_BOX="utm/ubuntu-24.04"
WORK_DIR="$(mktemp -d /tmp/utm-patch.XXXXXX)"
# ─────────────────────────────────────────────────────────────────────────────

cleanup() {
  echo "→ Cleaning up work directory: $WORK_DIR"
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  UTM box patcher — Virtualization.framework + nested virt ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo

#vagrant box remove $SOURCE_BOX
vagrant box add $SOURCE_BOX

# ── Step 1: Locate or add the source box ─────────────────────────────────────
echo "▶ Step 1: Ensuring source box '${SOURCE_BOX}' is available locally…"

if vagrant box list 2>/dev/null | grep -q "^${SOURCE_BOX}.*utm"; then
  echo "  ✓ Box already present locally."
else
  echo "  ↓ Box not found — downloading via 'vagrant box add'…"
  vagrant box add --provider utm "$SOURCE_BOX"
fi

# ── Step 2: Find the .box file on disk ───────────────────────────────────────
echo
echo "▶ Step 2: Locating the cached .box file…"

# Vagrant stores boxes under ~/.vagrant.d/boxes/<name>/<version>/<arch>/utm/
BOX_FILE=$(find "$HOME/.vagrant.d/boxes" -path "*$(echo "$SOURCE_BOX" | sed "s/\//-VAGRANTSLASH-/")*/*/box.utm" \
  -o -path "*$(echo "$SOURCE_BOX" | tr '/' '-')*/*/box.utm" 2>/dev/null | head -1 || true)

if [[ -z "$BOX_FILE" ]]; then
  echo "  ✗ Could not locate the .box file under ~/.vagrant.d/boxes."
  echo "    Try running:  vagrant box add --provider utm ${SOURCE_BOX}"
  exit 1
fi

echo "  ✓ Found: $BOX_FILE"

# ── Step 3: Locate the UTM bundle and its config.plist ───────────────────────
echo
echo "▶ Step 3: Locating config.plist inside the .utm bundle…"

CONFIG_PLIST=$(find "$BOX_FILE" -name "config.plist" | head -1)
if [[ -z "$CONFIG_PLIST" ]]; then
  echo "  ✗ No config.plist found — unexpected box structure."
  exit 1
fi
echo "  ✓ Found: $CONFIG_PLIST"

# ── Step 5: Patch config.plist ───────────────────────────────────────────────
echo
echo "▶ Step 4: Patching config.plist…"
cp "$CONFIG_PLIST" "${CONFIG_PLIST}.bak"
 
set +e
# plutil operates on XML plists directly; convert from binary if needed.
plutil -convert xml1 "$CONFIG_PLIST"
 
# ── 1. Switch backend to Apple Virtualization.framework ──────────────────────
# Top-level "backendType" integer: 0 = QEMU, 1 = Apple Virtualization.framework
if plutil -extract backendType raw "$CONFIG_PLIST" &>/dev/null; then
  echo "  • backendType → 1 (Apple Virtualization.framework)"
  plutil -replace backendType -integer 1 "$CONFIG_PLIST"
else
  echo "  • backendType not found — inserting as 1 (Apple Virtualization.framework)"
  plutil -insert backendType -integer 1 "$CONFIG_PLIST"
fi
 
# Nested dict variant: Backend = "Apple"
if plutil -extract Backend raw "$CONFIG_PLIST" &>/dev/null; then
  echo "  • Backend → 'Apple'"
  plutil -replace Backend -string "Apple" "$CONFIG_PLIST"
fi
 
# ── 2. Enable nested virtualisation ──────────────────────────────────────────
# The flag lives under the Apple backend configuration dict.
# Key path: Backend.isNestedVirtualizationEnabled (bool)
if plutil -extract Backend.isNestedVirtualizationEnabled raw "$CONFIG_PLIST" &>/dev/null; then
  echo "  • Backend.isNestedVirtualizationEnabled → true"
  plutil -replace Backend.isNestedVirtualizationEnabled -bool true "$CONFIG_PLIST"
else
  # Flat top-level key used by some UTM builds
  if plutil -extract isNestedVirtualizationEnabled raw "$CONFIG_PLIST" &>/dev/null; then
    echo "  • isNestedVirtualizationEnabled → true"
    plutil -replace isNestedVirtualizationEnabled -bool true "$CONFIG_PLIST"
  else
    echo "  • isNestedVirtualizationEnabled not found — inserting at root"
    plutil -insert isNestedVirtualizationEnabled -bool true "$CONFIG_PLIST"
  fi
fi
 
# ── 3. Disable QEMU Hypervisor.framework if present ─────────────────────────
# UseHypervisor must be false when using the Apple VF backend.
if plutil -extract UseHypervisor raw "$CONFIG_PLIST" &>/dev/null; then
  echo "  • UseHypervisor → false (incompatible with Apple VF backend)"
  plutil -replace UseHypervisor -bool false "$CONFIG_PLIST"
fi

# 4. Remove the entire QEMU dict
plutil -remove QEMU "$CONFIG_PLIST"

# 5. Fix network hardware names (virtio-net-pci → virtio-net)
plutil -replace Network.0.Hardware -string "virtio-net" "$CONFIG_PLIST"
plutil -replace Network.1.Hardware -string "virtio-net" "$CONFIG_PLIST"

# 6. Remove Serial console (Ptty is QEMU-specific; Apple VF uses Virtio serial)
plutil -remove Serial "$CONFIG_PLIST"

# 7. Fix System: remove QEMU machine target and CPU flags
plutil -remove System.Target "$CONFIG_PLIST"
plutil -remove System.CPU "$CONFIG_PLIST"
plutil -remove System.CPUFlagsAdd "$CONFIG_PLIST"
plutil -remove System.CPUFlagsRemove "$CONFIG_PLIST"
plutil -remove System.ForceMulticore "$CONFIG_PLIST"
plutil -remove System.JITCacheSize "$CONFIG_PLIST"

# 8. Fix USB: Apple VF only supports USB 2.0
plutil -replace Input.UsbBusSupport -string "2.0" "$CONFIG_PLIST"

# 9. Add Virtualization dict (required by Apple VF backend)
plutil -insert Virtualization -dictionary "$CONFIG_PLIST"
plutil -insert Virtualization.Entropy -bool true "$CONFIG_PLIST"

# 10. Add System.Boot dict
plutil -insert System.Boot -dictionary "$CONFIG_PLIST"
plutil -insert System.Boot.EfiVariableStoragePath -string "efi_vars.fd" "$CONFIG_PLIST"
plutil -insert System.Boot.OperatingSystem -string "Linux" "$CONFIG_PLIST"
plutil -insert System.Boot.UEFIBoot -bool true "$CONFIG_PLIST"

# 11. Add System.GenericPlatform with a fresh machine identifier
#    (UTM will regenerate this on first boot if the data is valid base64)
MACHINE_ID=$(plutil -extract System.GenericPlatform.machineIdentifier raw \
  ~/Library/Containers/com.utmapp.UTM/Data/Documents/*.utm/config.plist)

plutil -remove System.GenericPlatform "$CONFIG_PLIST" 2>/dev/null || true
plutil -insert System.GenericPlatform -dictionary "$CONFIG_PLIST"
plutil -insert System.GenericPlatform.machineIdentifier -data "$MACHINE_ID" "$CONFIG_PLIST"

# 12. Strip Network entries down to just MacAddress + Mode
plutil -remove Network.0.Hardware "$CONFIG_PLIST"
plutil -remove Network.0.IsolateFromHost "$CONFIG_PLIST"
plutil -remove Network.0.PortForward "$CONFIG_PLIST"
plutil -remove Network.1 "$CONFIG_PLIST"  # drop the Emulated NIC entirely

# 13. Fix Drive: replace QEMU Interface keys with Nvme bool
plutil -remove Drive.0.Interface "$CONFIG_PLIST"
plutil -remove Drive.0.InterfaceVersion "$CONFIG_PLIST"
plutil -remove Drive.0.ImageType "$CONFIG_PLIST"
plutil -insert Drive.0.Nvme -bool false "$CONFIG_PLIST"

plutil -replace System.CPUCount -integer 2 "$CONFIG_PLIST"

# 14. Remove Input dict (not used by Apple VF)
plutil -remove Input "$CONFIG_PLIST"

plutil -remove Virtualization "$CONFIG_PLIST" 2>/dev/null || true
plutil -insert Virtualization -dictionary "$CONFIG_PLIST"
plutil -insert Virtualization.Audio -bool true "$CONFIG_PLIST"
plutil -insert Virtualization.Balloon -bool true "$CONFIG_PLIST"
plutil -insert Virtualization.ClipboardSharing -bool true "$CONFIG_PLIST"
plutil -insert Virtualization.Entropy -bool true "$CONFIG_PLIST"
plutil -insert Virtualization.Keyboard -string "Generic" "$CONFIG_PLIST"
plutil -insert Virtualization.Pointer -string "Mouse" "$CONFIG_PLIST"
plutil -insert Virtualization.Rosetta -bool false "$CONFIG_PLIST"

plutil -insert Serial -array "$CONFIG_PLIST" 2>/dev/null || true
plutil -remove Sharing "$CONFIG_PLIST" 2>/dev/null || true

echo "  ✓ config.plist patched successfully."

## Convert qcow2
echo "Converting qcow2 to img"
QCOW_PATH=$(find "$BOX_FILE/Data/" -type f -name "*.qcow2")
RAW_PATH=${QCOW_PATH%.*}.img
qemu-img convert -f qcow2 -O raw $QCOW_PATH $RAW_PATH

plutil -replace Drive.0.ImageName \
  -string "7FB247A3-DC9F-4A61-A123-0AEE1BEEC636.img" \
  "$CONFIG_PLIST"

# ── Done ─────────────────────────────────────────────────────────────────────
echo
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✓ Done! Your patched box is ready.                      ║"
echo "╚══════════════════════════════════════════════════════════╝"
