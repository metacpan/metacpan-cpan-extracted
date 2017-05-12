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

    sub REPR {
        my $class = shift;
        my $instance = {};
        $instance->{__CLASS__} = $class;
        $instance->{__IDENT__} = 0+$instance;
        return $instance;
    }
}

{
    my $o = Foo->new;
    isa_ok($o, 'Foo');
    isa_ok($o, 'UNIVERSAL::Object');

    ok(exists $o->{foo}, '... got the expected slot');
    is($o->{foo}, 'FOO', '... the expected slot has the expected value');

    ok(exists $o->{__CLASS__}, '... got the expected slot');
    is($o->{__CLASS__}, 'Foo', '... the expected slot has the expected value');

    ok(exists $o->{__IDENT__}, '... got the expected slot');
    is($o->{__IDENT__}, 0+$o, '... the expected slot has the expected value');
}

{
    my $o = Foo->new( foo => 'BAR' );
    isa_ok($o, 'Foo');
    isa_ok($o, 'UNIVERSAL::Object');

    ok(exists $o->{foo}, '... got the expected slot');
    is($o->{foo}, 'BAR', '... the expected slot has the expected value');

    ok(exists $o->{__CLASS__}, '... got the expected slot');
    is($o->{__CLASS__}, 'Foo', '... the expected slot has the expected value');

    ok(exists $o->{__IDENT__}, '... got the expected slot');
    is($o->{__IDENT__}, 0+$o, '... the expected slot has the expected value');
}


