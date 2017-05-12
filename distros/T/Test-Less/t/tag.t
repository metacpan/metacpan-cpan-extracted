use t::TestLess tests => 4;

reset_test_env;

ok(not -e 't/Test-Less/index.txt');

my $t = test_less_new;
$t->tag(qw(foo bar t/tests/one.t));

ok(-e 't/Test-Less/index.txt');

check_index_content(next_block->expected);

$t->tag(qw(bar baz t/tests/two.t t/tests/three.t));

check_index_content(next_block->expected);

__DATA__
===
--- expected
bar t/tests/one.t
foo t/tests/one.t


===
--- expected
bar t/tests/one.t
bar t/tests/three.t
bar t/tests/two.t
baz t/tests/three.t
baz t/tests/two.t
foo t/tests/one.t



