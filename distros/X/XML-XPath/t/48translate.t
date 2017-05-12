use strict;
use warnings;
use Test::More;
use XML::XPath;

my $xp = XML::XPath->new(ioref => *DATA);
ok($xp);

is($xp->findvalue('translate("1,234.56",",","")'), 1234.56);
is($xp->findvalue('translate("bar","abc","ABC")'), "BAr");
is($xp->findvalue('translate("--aaa--","abc-","ABC")'), "AAA");

done_testing();

__DATA__
<foo/>