#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => 'Scalar::Lazy is required for this test'
        unless eval 'use Scalar::Lazy;1;';
    plan 'no_plan';

    use_ok('UNIVERSAL::Object');
}

=pod

NOTE:
Scalar::Lazy is also a possible candidate for
the deferred values, it does not try to hide
evidence of it's presence and is implemented
with C<tie> so can be very slow.

It also requires you to force the value
in some cases, which (again) is not always
ideal.

=cut

{
    package Foo;
    use strict;
    use warnings;

    our @ISA = ('UNIVERSAL::Object');
    our %HAS = (
        baz => sub { undef },
        bar => sub {
            my ($self) = @_;
            Scalar::Lazy::lazy {
                $self->{baz}
                    ? 'Foo::bar->' . $self->{baz}
                    : undef
            };
        },
    );

    sub baz { $_[0]->{baz} }
    sub bar { Scalar::Lazy::force( $_[0]->{bar} ) }
}

{
    my $foo = Foo->new;
    isa_ok($foo, 'Foo');

    is($foo->baz, undef, '... got the expected value');
    is($foo->bar, undef, '... got the expected value');
}

{
    my $foo = Foo->new;
    isa_ok($foo, 'Foo');

    is($foo->baz, undef, '... got the expected value');
    $foo->{baz} = 'Foo::baz';
    is($foo->bar, 'Foo::bar->Foo::baz', '... got the expected (lazy) value');
}

{
    my $foo = Foo->new( baz => 'Foo::baz' );
    isa_ok($foo, 'Foo');

    is($foo->baz, 'Foo::baz', '... got the expected value');
    is($foo->bar, 'Foo::bar->Foo::baz', '... got the expected value');
}


1;

