use Test::More;
use Test::JSON::Entails;
use Test::Builder::Tester tests => 1;

my $foo = bless { foo => 1 }, 'FOO';
my $bar = bless { foo => 1, bar => 2 }, 'BAR';

test_out("ok 1");
subsumes { foo => 1 } => $foo;

test_out("ok 2");
subsumes $foo => { foo => 1 };

test_out("not ok 3 - missing");
test_fail(+2);
test_diag("missing /bar");
subsumes $foo => $bar, 'missing';

#test_out("ok 4 - blessed");
#subsumes $bar => $foo, 'blessed';

test_test("test entailment on blessed structures");
