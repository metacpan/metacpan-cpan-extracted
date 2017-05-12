use strict;
use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Util;
# use Test::More tests => 2;
use Test::More "no_plan";

ok( my $xu = XHTML::Util->new,
    "XHTML::Util->new " );
