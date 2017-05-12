#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object');
}

=pod

Test inheriting from a class which also
takes the different API for `new` and
even showing how you could handle the
old API as well.

=cut

{
    package Baz;
    use strict;
    use warnings;

    sub new {
        my ($class, $value) = @_;
        bless { baz => $value } => $class;
    }

    sub baz { $_[0]->{baz} }
}

{
    package Foo::Baz;
    use strict;
    use warnings;
    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object', 'Baz') };
    our %HAS; BEGIN { %HAS = (foo => sub { 'FOO' }) };

    sub BUILDARGS {
        my $class = shift;
        # look for the old API case ...
        if ( $_[0] && not(ref($_[0])) && scalar(@_) == 1 ) {
            # and transform it ...
            return +{ baz => $_[0] };
        }
        else {
            # otherwise, let the superclass handle it
            return $class->SUPER::BUILDARGS( @_ );
        }
    }

    sub REPR {
        my ($class, $proto) = @_;
        # now feed the old constructor
        # the expected API
        $class->Baz::new( $proto->{baz} );
    }

    sub foo { $_[0]->{foo} }
}


{
    my $o = Foo::Baz->new;
    isa_ok($o, 'Foo::Baz');
    isa_ok($o, 'UNIVERSAL::Object');
    isa_ok($o, 'Baz');

    is($o->foo, 'FOO', '... the expected slot has the expected value');
    is($o->baz, undef, '... the expected slot has the expected value');
}

{
    my $o = Foo::Baz->new( foo => 'BAR' );
    isa_ok($o, 'Foo::Baz');
    isa_ok($o, 'UNIVERSAL::Object');
    isa_ok($o, 'Baz');

    is($o->foo, 'BAR', '... the expected slot has the expected value');
    is($o->baz, undef, '... the expected slot has the expected value');
}

{
    my $o = Foo::Baz->new( baz => 'GORCH' );
    isa_ok($o, 'Foo::Baz');
    isa_ok($o, 'UNIVERSAL::Object');
    isa_ok($o, 'Baz');

    is($o->foo, 'FOO', '... the expected slot has the expected value');
    is($o->baz, 'GORCH', '... the expected slot has the expected value');
}

{
    my $o = Foo::Baz->new( 'GORCH' );
    isa_ok($o, 'Foo::Baz');
    isa_ok($o, 'UNIVERSAL::Object');
    isa_ok($o, 'Baz');

    is($o->foo, 'FOO', '... the expected slot has the expected value');
    is($o->baz, 'GORCH', '... the expected slot has the expected value');
}

