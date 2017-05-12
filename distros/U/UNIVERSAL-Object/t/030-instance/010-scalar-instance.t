#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object');
}

=pod

NOTE:
This is an example of what needs to be done to override
the base HASH instance type with a SCALAR ref instead.

=cut

{
    package Foo;
    use strict;
    use warnings;
    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') };

    sub BUILDARGS { +{ arg => $_[1] } }
    sub REPR { \(my $x) }
    sub CREATE {
        my ($class, $proto) = @_;
        my $self = $class->REPR;
        $$self = $proto->{arg};
        $self;
    }
}

{
    my $o = Foo->new( 'BAR' );
    isa_ok($o, 'Foo');
    isa_ok($o, 'UNIVERSAL::Object');

    is($$o, 'BAR', '... the expected instance has the expected value');
}

{
    my $o = Foo->new( { baz => 'BAR' } );
    isa_ok($o, 'Foo');
    isa_ok($o, 'UNIVERSAL::Object');

    is(${$o}->{baz}, 'BAR', '... the expected instance has the expected value');
}


