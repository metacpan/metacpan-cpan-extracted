use strict;
use warnings;
use Test::More;
use Variable::Declaration;

my @OK = (
    '$foo'                 => [0, [tv('$foo')]],
    '$foo#bar'             => [0, [tv('$foo#bar')]],
    'Str $foo'             => [0, [tv('Str $foo')]],
    '($foo)'               => [1, [tv('$foo')]],
    '( $foo)'              => [1, [tv('$foo')]],
    '($foo )'              => [1, [tv('$foo ')]],
    '(Str $foo)'           => [1, [tv('Str $foo')]],
    '(Str $foo, $bar)'     => [1, [tv('Str $foo'), tv('$bar')]],
    '(Str $foo, Int $bar)' => [1, [tv('Str $foo'), tv('Int $bar')]],
    '($foo, Int $bar)'     => [1, [tv('$foo'), tv('Int $bar')]],
);

my @NG = (
    'foo',
    '<$foo>',
);

sub tv {
    my $expression = shift;
    Variable::Declaration::_parse_type_var($expression)
}

sub check_ok {
    my ($expression, $expected) = @_;
    my $got = Variable::Declaration::_parse_type_varlist($expression);

    note "'$expression'";
    is $got->{is_list_context}, $expected->[0], "is_list_context: @{[$expected->[0]]}";
    is_deeply $got->{type_vars}, $expected->[1], "type_vars: @{[explain($expected->[1])]}";
    note explain $got unless $got;
}

sub check_ng {
    my $expression = shift;
    my $got = Variable::Declaration::_parse_type_varlist($expression);

    note "'$expression'";
    is $got, undef;
    note explain $got if $got;
}

subtest 'case ok' => sub {
    while (@OK) {
        check_ok(shift @OK, shift @OK);
    }
};

subtest 'case ng' => sub {
    check_ng($_) for @NG;
};

done_testing;
