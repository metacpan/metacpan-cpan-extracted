use strict;
use Test::More;
require "t/lf.pl";

BEGIN { plan tests => 1 }

foreach my $lang (qw(flowedsp)) {
    dounfoldtest($lang, $lang, 'FLOWEDSP');
}

1;
