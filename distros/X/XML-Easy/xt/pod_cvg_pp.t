use warnings;
use strict;

do "./t/setup_pp.pl" or die $@ || $!;
do "./xt/pod_cvg.t" or die $@ || $!;

1;
