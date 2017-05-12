use t::TestLess;

plan tests => 1 * blocks;

reset_test_env;
# ok(not -e 't/Test-Less/index.txt');
is(next_block->index, '');
# ok(-e 't/Test-Less/index.txt');

filters {
    spec => [qw(chomp split run_list join)],
};

run_is spec => 'files';

sub run_list {
    test_less_new->list(@_);
}

sub join {
    join "\n", @_, '';
}

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
--- spec
baz
--- files
t/tests/one.t
t/tests/two.t

===
--- spec
baz bar
--- files
t/tests/one.t
t/tests/three.t
t/tests/two.t

===
--- spec
bar,baz
--- files
t/tests/two.t

===
--- spec
bar,^baz
--- files
t/tests/three.t

===
--- spec
foo,^bar baz
--- files
t/tests/four.t
t/tests/one.t
t/tests/two.t

===
--- spec
foo,^bar baz x.x
--- files
t/tests/four.t
t/tests/one.t
t/tests/two.t
x.x

===
--- spec
bar,^t/tests/two.t
--- files
t/tests/three.t

