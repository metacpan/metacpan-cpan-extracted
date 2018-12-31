use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";
require "t/lb.pl";

BEGIN { plan tests => 5 }

dotest('ecclesiazusae', 'ecclesiazusae');
dotest('ecclesiazusae', 'ecclesiazusae.ColumnsMax', Urgent => 'FORCE');
dotest('ecclesiazusae', 'ecclesiazusae.CharactersMax', CharMax => 79);
dotest('ecclesiazusae', 'ecclesiazusae.ColumnsMin',
       ColMin => 7, ColMax => 66, Urgent => 'FORCE');

eval {
    dotest('ecclesiazusae', 'ecclesiazusae', Urgent => 'CROAK');
};
ok($@ =~ /^Excessive line was found/, 'CROAK');

1;

