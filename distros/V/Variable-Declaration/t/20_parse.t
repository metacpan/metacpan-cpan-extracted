use strict;
use warnings;
use Test::More;
use Variable::Declaration;

my @CHECK =                 qw/statement type_varlist assign_to eq assign attributes/;
my @OK = (
    '$foo'               => ['$foo',              '$foo',       '$foo',    undef, undef, undef],
    '$foo;bar'           => ['$foo',              '$foo',       '$foo',    undef, undef, undef],
    '$foo}bar'           => ['$foo',              '$foo',       '$foo',    undef, undef, undef],
    '$foo} {}'           => ['$foo',              '$foo',       '$foo',    undef, undef, undef],
    '$foo#bar'           => ['$foo#bar',          '$foo#bar',   '$foo#bar',    undef, undef, undef],

    '$foo = "hello"'     => ['$foo = "hello"',    '$foo ',       '$foo ',    '=', '"hello"', undef],
    '$foo = []'          => ['$foo = []',         '$foo ',       '$foo ',    '=', '[]', undef],
    '$foo = {}'          => ['$foo = {}',         '$foo ',       '$foo ',    '=', '{}', undef],
    '$foo = hello'       => ['$foo = hello',      '$foo ',       '$foo ',    '=', 'hello', undef],
    '$foo = hello()'     => ['$foo = hello()',    '$foo ',       '$foo ',    '=', 'hello()', undef],
    '$foo = hello("a")'  => ['$foo = hello("a")', '$foo ',       '$foo ',    '=', 'hello("a")', undef],
    '$foo = do {}'       => ['$foo = do {}',      '$foo ',       '$foo ',    '=', 'do {}', undef],
    '$foo = eval {}'     => ['$foo = eval {}',    '$foo ',       '$foo ',    '=', 'eval {}', undef],
    '$foo = fg ? a : b'  => ['$foo = fg ? a : b', '$foo ',       '$foo ',    '=', 'fg ? a : b', undef],

    '$foo="hello"'       => ['$foo="hello"',      '$foo',       '$foo',    '=', '"hello"', undef],
    '$foo= "hello"'      => ['$foo= "hello"',     '$foo',       '$foo',    '=', '"hello"', undef],
    '$foo ="hello"'      => ['$foo ="hello"',     '$foo ',      '$foo ',   '=', '"hello"', undef],

    '$foo = "hello";'    => ['$foo = "hello"',    '$foo ',       '$foo ',    '=', '"hello"', undef],
    '$foo = "hello"}'    => ['$foo = "hello"',    '$foo ',       '$foo ',    '=', '"hello"', undef],
    '$foo = "hello"} {}' => ['$foo = "hello"',    '$foo ',       '$foo ',    '=', '"hello"', undef],
    '$foo = "hello"#bar' => ['$foo = "hello"',    '$foo ',       '$foo ',    '=', '"hello"', undef],

    'Str $foo = "hello"'                         => ['Str $foo = "hello"',                         'Str $foo ',       'Str $foo ',    '=', '"hello"', undef],
    'Str $foo:Good = "hello"'                    => ['Str $foo:Good = "hello"',                    'Str $foo',       'Str $foo:Good ',    '=', '"hello"', ':Good'],
    'Str $foo:Good :Better = "hello"'            => ['Str $foo:Good :Better = "hello"',            'Str $foo',       'Str $foo:Good :Better ',    '=', '"hello"', ':Good :Better'],

    '($foo) = ("hello")'                         => ['($foo) = ("hello")',                         '($foo)',       '($foo) ',    '=', '("hello")', undef],
    '($foo):Good = ("hello")'                    => ['($foo):Good = ("hello")',                    '($foo)',       '($foo):Good ',    '=', '("hello")', ':Good'],
    '($foo, $bar) = ("hello", "world")'          => ['($foo, $bar) = ("hello", "world")',          '($foo, $bar)',       '($foo, $bar) ',    '=', '("hello", "world")', undef],
    '($foo, $bar):Good = ("hello", "world")'     => ['($foo, $bar):Good = ("hello", "world")',     '($foo, $bar)',       '($foo, $bar):Good ',    '=', '("hello", "world")', ':Good'],

    '(Str $foo) = ("hello")'                     => ['(Str $foo) = ("hello")',                     '(Str $foo)',       '(Str $foo) ',    '=', '("hello")', undef],
    '(Str $foo):Good = ("hello")'                => ['(Str $foo):Good = ("hello")',                '(Str $foo)',       '(Str $foo):Good ',    '=', '("hello")', ':Good'],
    '(Str $foo, $bar) = ("hello", "world")'      => ['(Str $foo, $bar) = ("hello", "world")',      '(Str $foo, $bar)',       '(Str $foo, $bar) ',    '=', '("hello", "world")', undef],
    '(Str $foo, $bar):Good = ("hello", "world")' => ['(Str $foo, $bar):Good = ("hello", "world")', '(Str $foo, $bar)',       '(Str $foo, $bar):Good ',    '=', '("hello", "world")', ':Good'],
    '(Str $foo, Int8 $bar) = ("hello", "world")' => ['(Str $foo, Int8 $bar) = ("hello", "world")', '(Str $foo, Int8 $bar)',       '(Str $foo, Int8 $bar) ',    '=', '("hello", "world")', undef],
    '($foo, Int8 $bar) = ("hello", "world")'     => ['($foo, Int8 $bar) = ("hello", "world")',     '($foo, Int8 $bar)',       '($foo, Int8 $bar) ',    '=', '("hello", "world")', undef],
);

sub check {
    my ($src, $expected) = @_;
    my $got = Variable::Declaration::_parse($src);

    note "'$src'";
    for (my $i = 0; $i < @CHECK; $i++) {
        my $c = $CHECK[$i];
        is $got->{$c}, $expected->[$i], "$c: '@{[$expected->[$i] || '']}'";
    }
}

subtest 'case ok' => sub {
    while (@OK) {
        check(shift @OK, shift @OK);
    }
};

done_testing;
