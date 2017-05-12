use t::TestLess;

plan tests => 1 * blocks;

reset_test_env;

is(next_block->index, '');

run_is test => 'output';

__DATA__
===
--- index write_file=t/Test-Less/index.txt
foo     t/tests/one.t
foo     t/tests/two.t
foo     t/tests/three.t
foo     t/tests/four.t
bar     t/tests/two.t
bar     t/tests/three.t
baz     t/tests/one.t
baz     t/tests/two.t

===
--- test eval_stdout
Test::Less->new->run('-list', 'foo,^bar', 'baz');
--- output
t/tests/four.t
t/tests/one.t
t/tests/two.t
