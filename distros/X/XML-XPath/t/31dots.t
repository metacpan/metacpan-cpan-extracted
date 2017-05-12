use strict;
use warnings;
use Test::More tests => 3;
use XML::XPath;

my $xp = XML::XPath->new(ioref => *DATA);
ok($xp);

my ($root, ) = $xp->findnodes('/.');
is $root->toString(), '<page />';
ok not $xp->findnodes('/..');

__END__
<page></page>