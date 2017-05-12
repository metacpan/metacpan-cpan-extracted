use strict;
use warnings;
use Test::More tests => 7;
use XML::XPath;

my $xp = XML::XPath->new(ioref => *DATA);
ok($xp);

my $resultset = $xp->find('substring-after("1999/04/01","/")');
ok($resultset->isa('XML::XPath::Literal'));
is($resultset, '04/01');

$resultset = $xp->find('substring-after("1999/04/01","19")');
ok($resultset->isa('XML::XPath::Literal'));
is($resultset, '99/04/01');

$resultset = $xp->find('substring-after("1999/04/01","2")');
ok($resultset->isa('XML::XPath::Literal'));
is($resultset, '');

__DATA__
<foo/>