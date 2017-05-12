use warnings;
use strict;

do "t/setup_pp.pl" or die $@ || $!;
do "t/node_object.t" or die $@ || $!;

1;
