use t::TestLess tests => 4;

reset_test_env;

ok(not -e 't/Test-Less/index.txt');

my $t = Test::Less->new;

is(next_block->index, '');;

$t->untag(qw(foo bar t/tests/two.t));

check_index_content(next_block->expected);

$t->untag(qw(bar t/tests/one.t t/tests/three.t));

check_index_content(next_block->expected);

__DATA__
===
--- index write_file=t/Test-Less/index.txt
foo     t/tests/one.t   Ingy is foo
foo     t/tests/two.t
foo     t/tests/three.t
bar     t/tests/one.t   Ingy is at the bar
bar     t/tests/two.t
bar     t/tests/three.t

===
--- expected
bar t/tests/one.t	Ingy is at the bar
bar t/tests/three.t
foo t/tests/one.t	Ingy is foo
foo t/tests/three.t

===
--- expected
foo t/tests/one.t	Ingy is foo
foo t/tests/three.t
