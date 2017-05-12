use strict;
use warnings;

use FindBin qw($Bin);

$ENV{MOUSE_PUREPERL} = 1;
do "$Bin/mouse.t";
die $@ if $@;
