use t::TestLess;

plan tests => 1 * blocks;

filters {
    spec => [qw(split parse)],
    parsed => 'eval',
};

run_is_deeply spec => 'parsed';

sub parse {
    Test::Less->parse_spec(@_);
}

__DATA__
===
--- spec
foo bar
--- parsed
[qw(foo bar)]

===
--- spec
foo,bar
--- parsed
[[qw(foo bar)]]

===
--- spec
foo,bar baz
--- parsed
[[qw(foo bar)], 'baz']

===
--- spec
foo,bar ^baz
--- parsed
[[qw(foo bar)], '^baz']

===
--- spec
foo,^bar baz
--- parsed
[[qw(foo ^bar)], 'baz']

