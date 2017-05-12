#
#===============================================================================
#
#         FILE: 01-base.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
#      COMPANY: 
#      VERSION: 1.0
#      CREATED: 10/8/2012 9:34:51 AM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use Win32::Utilization;
use Test::More tests => 3;                      # last test to print
SKIP:{
	skip "CPU_per", 1;
ok(CPU_per(), ' CPU test');
};
ok(mem_per(), ' mem test');
ok(drive_per('c'), ' drive test');
done_testing();
