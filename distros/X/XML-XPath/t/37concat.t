use strict;
use warnings;
use Test::More tests => 3;
use XML::XPath;

my $xp = XML::XPath->new(ioref => *DATA);
ok($xp);

my $resultset = $xp->find('concat("1","2","3"');
ok($resultset->isa('XML::XPath::Literal'));
is($resultset, '123');

__DATA__
<foo/>