use strict;
use warnings;
use Test::More;
use Variable::Declaration;

my @OK = (
    +{
        declaration      => 'let',
        perl_declaration => 'my',
        is_list_context  => 0,
        type_vars        => [ { var => '$foo' } ],
        attributes       => undef,
        assign           => undef,
        level            => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my $foo', 'simple',
    +{
        declaration      => 'let',
        perl_declaration => 'my',
        is_list_context  => 1,
        type_vars        => [ { var => '$foo' } ],
        attributes       => undef,
        assign           => undef,
        level            => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my ($foo)', 'is_list_context => 1',
    +{
        declaration      => 'let',
        perl_declaration => 'my',
        is_list_context  => 0,
        type_vars        => [ { var => '$foo' } ],
        attributes       => ':Good',
        assign           => undef,
        level            => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my $foo:Good', "attributes => ':Good'",
    +{
        declaration      => 'let',
        perl_declaration => 'my',
        is_list_context  => 0,
        type_vars        => [ { var => '$foo' } ],
        attributes       => undef,
        assign           => "'hello'",
        level            => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my $foo = \'hello\'', "assign => 'hello'",
    +{
        declaration      => 'let',
        perl_declaration => 'my',
        is_list_context  => 0,
        type_vars        => [ { var => '$foo', type => 'Str' } ],
        attributes       => undef,
        assign           => undef,
        level            => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my $foo;Variable::Declaration::croak(Str->get_message($foo)) unless Str->check($foo);Variable::Declaration::type_tie($foo, Str, $foo)', "type => 'Str'",
    +{
        declaration      => 'let',
        perl_declaration => 'my',
        is_list_context  => 1,
        type_vars        => [ { var => '$foo' }, { var => '$bar' } ],
        attributes       => undef,
        assign           => undef,
        level            => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my ($foo, $bar)', "type_vars > 1",
    +{
        declaration      => 'let',
        perl_declaration => 'my',
        is_list_context  => 1,
        type_vars        => [ { var => '$foo', type => 'Str' }, { var => '$bar' } ],
        attributes       => undef,
        assign           => undef,
        level            => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my ($foo, $bar);Variable::Declaration::croak(Str->get_message($foo)) unless Str->check($foo);Variable::Declaration::type_tie($foo, Str, $foo)', "type_vars > 1 && type => 'Str'",
    +{
        declaration      => 'let',
        perl_declaration => 'my',
        is_list_context  => 1,
        type_vars        => [ { var => '$foo', type => 'Str' }, { var => '$bar', type => 'Int8' } ],
        attributes       => undef,
        assign           => undef,
        level            => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my ($foo, $bar);Variable::Declaration::croak(Str->get_message($foo)) unless Str->check($foo);Variable::Declaration::croak(Int8->get_message($bar)) unless Int8->check($bar);Variable::Declaration::type_tie($foo, Str, $foo);Variable::Declaration::type_tie($bar, Int8, $bar)', "type_vars > 1 && set types",
    +{
        declaration      => 'let',
        perl_declaration => 'my',
        is_list_context  => 0,
        type_vars        => [ { var => '$foo', type => 'Int' } ],
        attributes       => undef,
        assign           => 123,
        level            => 0,
    } => 'my $foo = 123', "level => 0",
    +{
        declaration      => 'let',
        perl_declaration => 'my',
        is_list_context  => 0,
        type_vars        => [ { var => '$foo', type => 'Int' } ],
        attributes       => undef,
        assign           => 123,
        level            => 1,
    } => 'my $foo = 123;Variable::Declaration::croak(Int->get_message($foo)) unless Int->check($foo)', "level => 1",
    +{
        declaration      => 'const',
        perl_declaration => 'my',
        is_list_context  => 0,
        type_vars        => [ { var => '$foo' } ],
        attributes       => undef,
        assign           => 123,
        level            => 1,
    } => 'my $foo = 123;Variable::Declaration::data_lock($foo)', "data lock",
);

sub check {
    my ($args, $expected, $msg) = @_;
    my $got = Variable::Declaration::_render_declaration($args);
    note "Case: $msg";
    note "'$expected'";
    is $got, $expected;
}

while (@OK) {
    check(shift @OK, shift @OK, shift @OK);
}

done_testing;
