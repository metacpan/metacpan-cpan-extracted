use strict;
use warnings;

use lib 'lib';

eval "use Win32::Detached"; # at this point the script will background itself
                     # if started via Win->Run or double-clicking,
                     # the console window will close

sleep 10; # so you can see the process in the task manager

print "moo"; # this will not show up anywhere
