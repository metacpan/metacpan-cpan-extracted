use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";
require "t/lb.pl";

BEGIN { plan tests => 13 }

foreach my $lang (qw(ar el fr he ja ja-a ko ko-decomp ru sa vi vi-decomp zh)) {
    dotest($lang, $lang);
}    

1;

