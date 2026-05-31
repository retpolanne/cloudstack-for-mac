#!/usr/bin/env sh
vagrant plugin uninstall vagrant_utm
vagrant plugin install vagrant_utm

PLUGIN_DIR=$HOME/.vagrant.d/gems/3.3.8/gems/vagrant_utm-0.1.5/

## Patch plugin directory mode
echo "Patching directoryShareMode"
SCRIPT=$PLUGIN_DIR/lib/vagrant_utm/scripts/customize_vm.applescript

# Back it up first
cp "$SCRIPT" "${SCRIPT}.bak"

# Comment out the offending line
sed -i '' \
  's/set directory share mode of config to directoryShareMode/-- set directory share mode of config to directoryShareMode/' \
  "$SCRIPT"

## Patch plugin driver path
echo "Patching plugin driver path"
DRIVER=$PLUGIN_DIR/lib/vagrant_utm/driver/version_4_5.rb

cp "$DRIVER" "${DRIVER}.bak"

sed -i '' \
  's|\.qcow2\$|.(qcow2\|img\|raw)$|g' \
  "$DRIVER"

## Patch arp stuff
echo "Patching plugin arp discovery"
DRIVER=$PLUGIN_DIR/lib/vagrant_utm/driver/version_4_5.rb

python3 - "$DRIVER" << 'PYEOF'
import sys

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

old = '''        def read_guest_ip
          output = execute("ip-address", @uuid)
          output.strip.split("\\n")
        end'''

new = '''        def read_guest_ip
          # utmctl ip-address is not supported for Apple VF backend.
          # Get the MAC from UTM via AppleScript and resolve via ARP.
          command = ["read_network_interfaces.applescript", @uuid]
          info = execute_osa_script(command)
          mac = nil
          info.split("\\n").each do |line|
            next unless (matcher = /^nic0,(.+)$/.match(line))
            mac = matcher[1]
            break
          end
          return [] if mac.nil?
          system("ping -c 1 -W 1 192.168.64.255 > /dev/null 2>&1")
          arp_output = `arp -an`
          arp_output.split("\\n").each do |line|
            next unless line.downcase.include?(mac.downcase)
            next unless (ip_match = line.match(/\\(([0-9.]+)\\)/))
            return [ip_match[1]]
          end
          []
        end'''

if old not in content:
    print("ERROR: could not find target method — already patched or whitespace mismatch")
    sys.exit(1)

with open(path, 'w') as f:
    f.write(content.replace(old, new, 1))

print("OK: read_guest_ip patched")
PYEOF
