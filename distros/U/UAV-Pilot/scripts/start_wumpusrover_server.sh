#!/bin/sh
# 
# HOW TO USE THIS
# 
# On your Raspberry Pi (running Raspbian), do:
# 
# 1) In "/etc/modprobe.d/raspi-blacklist.conf", remove "i2c_bcm2708"
# 2) Run "modprobe i2c_dev" and "modprobe i2c_bcm2708".  Add these 
#    two modules to the list in "/etc/modules"
# 3) Make sure "screen" is installed ("apt-get install screen")
# 4) Raspberry Pi at /etc/wumpusrover/start_wumpusrover_server.sh
# 5) Run "chmod +x /etc/wumpusrover/start_wumpusrover_server.sh"
# 6) As root, open /etc/rc.local in an editor, and add this to the end:
#
#     /etc/wumpusrover/start_wumpusrover_server.sh
#
# 7) Run '/etc/wumpusrover/start_wumpusrover_server.sh' manually (as root) to 
#    make sure everything is OK
#
# You can see the process running by attaching to screen as root with:
#
#     sudo screen -r wumpus
#
# I would love suggestions on how to run this without being root.  The I2C 
# interface on the Raspberry Pi accesses /dev/mem, which requires your user 
# to have write access there.  I tried playing around in udev, but still got 
# errors.
#

echo "Starting WumpusRover server"
screen -S wumpus -d -m /usr/local/bin/wumpusrover_server
echo "Done starting WumpusRover server"

exit 0
