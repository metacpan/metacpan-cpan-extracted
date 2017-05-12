use strict;
use warnings;
use Test::More tests => 5;
use XML::XPath;

my $xp = XML::XPath->new(ioref => *DATA);
ok($xp);

ok($xp->findvalue('4 div 2') == 2);
is $xp->findvalue('4 div 0'), 'Infinity';
is $xp->findvalue('-4 div 0'), '-Infinity';
is $xp->findvalue('0 div 0'), 'NaN';

__DATA__
<p></p>
