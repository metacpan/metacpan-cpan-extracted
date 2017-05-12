use strict;
use warnings;
use Test::More tests => 5;
use XML::XPath;

my $xp = XML::XPath->new(ioref => *DATA);
ok($xp);

my $resultset = $xp->find('contains("123","1"');
ok($resultset->isa('XML::XPath::Boolean'));
is($resultset->to_literal(), 'true');

$resultset = $xp->find('contains("123","4"');
ok($resultset->isa('XML::XPath::Boolean'));
is($resultset->to_literal(), 'false');

__DATA__
<foo/>