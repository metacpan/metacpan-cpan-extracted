use strict;
use Test::More;
require "t/lf.pl";

BEGIN { plan tests => 2 }

foreach my $lang (qw(fr ja)) {
    dowraptest($lang, $lang);
}    

1;

