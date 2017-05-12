#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => 'Data::Thunk is required for this test'
        unless eval 'use Data::Thunk;1;';
    plan 'no_plan';

    use_ok('UNIVERSAL::Object');
}

=pod

NOTE:
Data::Thunk is also a decent candidate for
the deferred values, however it also leaves
evidence of it's presence, though not as much
as Scalar::Defer does. It has a number of
dependencies though, so it might not be
suitable for all usages either.

And, it requires you to force the value
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
            Data::Thunk::lazy {
                $self->{baz}
                    ? 'Foo::bar->' . $self->{baz}
                    : undef
            };
        },
    );

    sub baz { $_[0]->{baz} }
    sub bar { Data::Thunk::force( $_[0]->{bar} ) }
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

