use warnings;
use strict;

do "t/setup_pp.pl" or die $@ || $!;
do "t/easy_module.t" or die $@ || $!;

1;
