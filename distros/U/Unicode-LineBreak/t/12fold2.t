use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";
require "t/lf.pl";

BEGIN { plan tests => 2 }

foreach my $lang (qw(fr ja)) {
    dowraptest($lang, $lang);
}    

1;

