use strict;
use warnings;
use Test::More tests => 5;
use XML::XPath;

my $xp = XML::XPath->new(ioref => *DATA);
ok($xp);

my $resultset = $xp->find('substring-before("1999/04/01","/")');
ok($resultset->isa('XML::XPath::Literal'));
is($resultset, '1999');

$resultset = $xp->find('substring-before("1999/04/01","?")');
ok($resultset->isa('XML::XPath::Literal'));
is($resultset, '');

__DATA__
<foo/>