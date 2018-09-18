#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object');
}

=pod

TODO:

=cut

{
    package Foo;
    use strict;
    use warnings;
    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') };
    our %HAS; BEGIN { %HAS = (foo => sub { 'FOO' }) };

    our %TRACKED;

    sub REPR {
        my $class = shift;
        my $instance = {};
        $TRACKED{ 0+$instance } = $instance;
        return $instance;
    }
}

{
    my $o = Foo->new;
    isa_ok($o, 'Foo');
    isa_ok($o, 'UNIVERSAL::Object');

    ok(exists $o->{foo}, '... got the expected slot');
    is($o->{foo}, 'FOO', '... the expected slot has the expected value');

    is($Foo::TRACKED{ 0+$o }, $o, '... got the expected tracked instance');
    is(scalar keys %Foo::TRACKED, 1, '... there is only one tracked instance');
}

{
    my $o = Foo->new( foo => 'BAR' );
    isa_ok($o, 'Foo');
    isa_ok($o, 'UNIVERSAL::Object');

    ok(exists $o->{foo}, '... got the expected slot');
    is($o->{foo}, 'BAR', '... the expected slot has the expected value');

    is($Foo::TRACKED{ 0+$o }, $o, '... got the expected tracked instance');
    is(scalar keys %Foo::TRACKED, 2, '... there are two tracked instances');
}


