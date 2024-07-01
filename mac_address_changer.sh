#!/bin/bash

###############################################################################
#                               R a c c o o n                                 #
###############################################################################
#  This script changes the MAC address of a specified network interface. If a
#  new MAC address is not provided, it generates a random MAC address.
#
#  Usage:
#    ./mac_address_changer.sh
#
#  Note:
#    This script requires root privileges to change the MAC address.
###############################################################################

# Function to generate a random MAC address
generate_random_mac() {
  hexchars="0123456789ABCDEF"
  echo "00:60:2F$( for i in {1..3}; do echo -n ${hexchars:$(( $RANDOM % 16 )):1}${hexchars:$(( $RANDOM % 16 )):1}; done | sed 's/../:&/g' )"
}

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Use sudo to run the script."
  exit 1
fi

# Prompt the user for the network interface
read -p "Enter the network interface (e.g., eth0, wlan0): " interface

# Validate the interface
if [[ -z "$interface" ]]; then
  echo "No interface specified. Exiting."
  exit 1
fi

# Prompt the user for the new MAC address
read -p "Enter the new MAC address (leave empty to generate a random MAC address): " new_mac

# Generate a random MAC address if not provided
if [[ -z "$new_mac" ]]; then
  new_mac=$(generate_random_mac)
  echo "Generated random MAC address: $new_mac"
fi

# Bring the network interface down
echo "Bringing down the interface $interface..."
sudo ip link set dev $interface down

# Change the MAC address
echo "Changing MAC address of $interface to $new_mac..."
sudo ip link set dev $interface address $new_mac

# Bring the network interface up
echo "Bringing up the interface $interface..."
sudo ip link set dev $interface up

# Verify the change
current_mac=$(ip link show $interface | grep link/ether | awk '{print $2}')
if [[ "$current_mac" == "$new_mac" ]]; then
  echo "MAC address successfully changed to $current_mac"
else
  echo "Failed to change MAC address."
fi
