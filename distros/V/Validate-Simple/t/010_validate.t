use strict;
use warnings;

use Validate::Simple;

use Test::More;

my @tests = (
    [
        number => [
            [ -1,        1 ],
            [ 3.1415926, 1 ],
            [ '100',     1 ],
            [ '0E0',     1 ],
            [ 1_000,     1 ],
            [ '1_000',   0 ],
            [ "text",    0 ],
            [ undef,     0 ],
            [ '-10',     1 ],
            [ '+10',     1 ],
            [ '-',       0 ],
            [ '+',       0 ],
            [ '1+1',     0 ],
            [ [],        0 ],
            [ bless({}, 'Foo::Bar'), 0 ],
        ],
    ],
    [
        positive => [
            [ -1,        0 ],
            [ 3.1416926, 1 ],
            [ 0,         0 ],
            [ 'text',    0 ],
            [ undef,     0 ],
        ],
    ],
    [
        non_negative => [
            [ -1,        0 ],
            [ 3.1416926, 1 ],
            [ 0,         1 ],
            [ 'text',    0 ],
            [ undef,     0 ],
        ],
    ],
    [
        negative => [
            [ -1,        1 ],
            [ 3.1416926, 0 ],
            [ 0,         0 ],
            [ 'text',    0 ],
            [ undef,     0 ],
        ],
    ],
    [
        non_positive => [
            [ -1,        1 ],
            [ 3.1416926, 0 ],
            [ 0,         1 ],
            [ 'text',    0 ],
            [ undef,     0 ],
        ],
    ],
    [
        integer => [
            [ -1,        1 ],
            [ 100,       1 ],
            [ 3.1416926, 0 ],
            [ 0,         1 ],
            [ 'text',    0 ],
            [ undef,     0 ],
            [ '10',      1 ],
            [ '-10',     1 ],
            [ {},        0 ],
        ]
    ],
    [
        positive_int => [
            [ -1,        0 ],
            [ 100,       1 ],
            [ 3.1416926, 0 ],
            [ 0,         0 ],
            [ 'text',    0 ],
            [ undef,     0 ],
            [ '10',      1 ],
            [ '-10',     0 ],
            [ {},        0 ],
        ],
    ],
    [
        non_negative_int => [
            [ -1,        0 ],
            [ 100,       1 ],
            [ 3.1416926, 0 ],
            [ 0,         1 ],
            [ 'text',    0 ],
            [ undef,     0 ],
            [ '10',      1 ],
            [ '-10',     0 ],
            [ {},        0 ],
        ],
    ],
    [
        negative_int => [
            [ -1,        1 ],
            [ 100,       0 ],
            [ 3.1416926, 0 ],
            [ 0,         0 ],
            [ 'text',    0 ],
            [ undef,     0 ],
            [ '10',      0 ],
            [ '-10',     1 ],
            [ {},        0 ],
        ],
    ],
    [
        non_positive_int => [
            [ -1,        1 ],
            [ 100,       0 ],
            [ 3.1416926, 0 ],
            [ 0,         1 ],
            [ 'text',    0 ],
            [ undef,     0 ],
            [ '10',      0 ],
            [ '-10',     1 ],
            [ {},        0 ],
        ],
    ],
    [
        string => [
            [ -1,        1 ],
            [ '',        1 ],
            [ 100,       1 ],
            [ 3.1416926, 1 ],
            [ 0,         1 ],
            [ 'text',    1 ],
            [ undef,     0 ],
            [ '10',      1 ],
            [ '-10',     1 ],
            [ {},        0 ],
        ],
    ],
    [
        array => [
            [ -1,        0 ],
            [ 100,       0 ],
            [ 3.1416926, 0 ],
            [ 0,         0 ],
            [ 'text',    0 ],
            [ undef,     0 ],
            [ '10',      0 ],
            [ '-10',     0 ],
            [ {},        0 ],
            [ [],        1 ],
            [ [1,2,'q'], 1 ],
            [ [{}],      1 ],
        ],
    ],
    [
        hash => [
            [ -1,        0 ],
            [ 100,       0 ],
            [ 3.1416926, 0 ],
            [ 0,         0 ],
            [ 'text',    0 ],
            [ undef,     0 ],
            [ '10',      0 ],
            [ '-10',     0 ],
            [ {},        1 ],
            [ [],        0 ],
            [ {1 =>2},   1 ],
            [ {1=>{}},   1 ],
        ],
    ],
    [
        code => [
            [ -1,        0 ],
            [ 3.1416926, 0 ],
            [ 'text',    0 ],
            [ undef,     0 ],
            [ {},        0 ],
            [ [],        0 ],
            [ sub { 1;}, 1 ],
        ],
    ],
);

my @enum_tests = (
    [ -1,     [1..5],                 0 ],
    [ 100,    [95..105],              1 ],
    [ 'text', [ qw/word text book/ ], 1 ],
    [ undef,  [ qw/a b c d e f/ ],    0 ],
    [ {},     [ 1 ],                  0 ],
    [ [],     [ 1 ],                  0 ],
);

for my $et ( @enum_tests ) {
    $et->[1] = { map { $_ => undef } @{ $et->[1]} };
}

push @tests, [ enum => \@enum_tests ];

my $test_count = 0;
for my $f ( @tests ) {
    for my $c ( @{ $f->[1] } ) {
        $test_count++;
    }
}

plan tests => $test_count + 2;

use_ok('Data::Types');
my $validate = new_ok( 'Validate::Simple' );

for my $test ( @tests ) {
    my ( $meth, @cases ) = ( $test->[0], @{ $test->[1] } );
    for my $c ( @cases ) {
        my $expected_true = pop @$c;
        my $printable = join(',', map {
            defined ? $_ : "[undef]";
        } @$c );
        $expected_true
            ? ok( $validate->$meth( @$c ), "'$meth' with <$printable> returns true" )
            : ok( !$validate->$meth( @$c ), "'$meth' with <$printable> returns false" );
    }
}

1;
