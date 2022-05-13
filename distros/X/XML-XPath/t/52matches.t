use strict;
use warnings;
use Test::More tests => 10;
use XML::XPath;

my $xp = XML::XPath->new(ioref => *DATA);
ok($xp);

my $resultset = $xp->find('matches("foo1bar", "[[:digit:]]")');
ok($resultset->isa('XML::XPath::Boolean'));
is($resultset->to_literal(), 'true');

$resultset = $xp->find('matches("foobar","[[:digit:]]")');
ok($resultset->isa('XML::XPath::Boolean'));
is($resultset->to_literal(), 'false');

$resultset = $xp->find('matches("foobar", "AR", "i")');
is($resultset->to_literal(), 'true');

$resultset = $xp->find('matches("foobar", "AR")');
is($resultset->to_literal(), 'false');

eval {
  $xp->find('matches("foobar", "x", "p")');
};
if ($@) {
  ok(1);
} else {
  ok(0);
}

$resultset = $xp->find('matches("foo[bar", "[bar", "q")');
is($resultset->to_literal(), 'true');

$resultset = $xp->find('matches("foobar", "foo . ar", "x")');
is($resultset->to_literal(), "true");

__DATA__
<foo/>
