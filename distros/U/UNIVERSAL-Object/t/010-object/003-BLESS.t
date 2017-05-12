#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object');
}

=pod

NOTE:
This test is kind of silly actually, the reason for 
adding BLESS was mostly to make CREATE easier to 
override, not to make BLESS something you want to 
override. So this test simply to make sure things 
are working as expected. 

=cut

{
    package Foo;
    use strict;
    use warnings;
    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') };
    our %HAS; BEGIN { %HAS = (foo => sub { 'FOO' }) };

    sub BLESS {
        my ($class, $proto) = @_;
        my $self = { %$proto };
        return bless $self => $class;
    }
}

{
    my $o = Foo->new;
    isa_ok($o, 'Foo');
    isa_ok($o, 'UNIVERSAL::Object');

    ok(not(exists $o->{foo}), '... got the expected slot');
    is($o->{foo}, undef, '... the expected slot has the expected value');
}

{
    my $o = Foo->new( foo => 'BAR', bar => 'BAZ' );
    isa_ok($o, 'Foo');
    isa_ok($o, 'UNIVERSAL::Object');

    ok(exists $o->{foo}, '... got the expected slot');
    is($o->{foo}, 'BAR', '... the expected slot has the expected value');

    ok(exists $o->{bar}, '... got the expected slot');
    is($o->{bar}, 'BAZ', '... the expected slot has the expected value');
}


