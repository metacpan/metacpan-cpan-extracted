use Test2::V0;

is(
    [<DATA>],
    ["foo\n", "bar\n", "baz\n"],
    "Got correct data section"
);

done_testing;

__DATA__
foo
bar
baz
