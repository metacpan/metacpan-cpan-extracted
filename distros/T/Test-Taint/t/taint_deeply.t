#!perl -T

## Two techniques that are bad in general but necessary in this test.
## no critic (Miscellanea::ProhibitTies)
## no critic (Modules::ProhibitMultiplePackages)

use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Taint tests => 111;

taint_checking_ok('Taint checking is on');

TAINT_A_HASH: {
    my %hash = (
        value   => 7,
        unknown => undef,
    );

    $hash{circular} = \%hash;

    untainted_ok( $hash{value}, 'Starts clean' );
    taint_deeply( \%hash );
    tainted_ok( $hash{value}, 'Gets dirty' );
    is( $hash{value}, 7, 'value stays the same' );

    $hash{value} =~ /\A(\d+)\z/ or die;
    $hash{value} = $1;

    untainted_ok( $hash{value}, 'Reclean' );
    is( $hash{value}, 7, 'value stays the same' );
}

TAINT_AN_ARRAY: {
    my @array = (
        7,
    );

    untainted_ok( $array[0], 'Starts clean' );
    taint_deeply( \@array );
    tainted_ok( $array[0], 'Gets dirty' );
    is( $array[0], 7, 'value stays the same' );

    $array[0] =~ /\A(\d+)\z/ or die;
    $array[0] = $1;

    untainted_ok( $array[0], 'Reclean' );
    is( $array[0], 7, 'value stays the same' );
}

TAINT_A_SCALAR: {
    my $scalar = 14;

    untainted_ok( $scalar, 'Starts clean' );
    taint_deeply( \$scalar );
    tainted_ok( $scalar, 'Gets dirty' );
    is( $scalar, 14, 'value stays the same' );

    $scalar =~ /\A(\d+)\z/ or die;
    $scalar = $1;

    untainted_ok( $scalar, 'Reclean' );
    is( $scalar, 14, 'value stays the same' );
}

TAINT_A_TYPEGLOB: {
    no strict 'vars';
    $x = 21;
    %x = (k1 => 28, k2 => 35, k3 => 42, k4 => 49);
    @x = (56, 63, 70, 77);

    untainted_ok( $x, 'Starts clean' );
    untainted_ok( $x{$_}, 'Starts clean' ) foreach keys %x;
    untainted_ok( $_, 'Starts clean' ) foreach @x;
    taint_deeply( \*x );
    tainted_ok( $x, 'Gets dirty' );
    tainted_ok( $x{$_}, 'Gets dirty' ) foreach keys %x;
    tainted_ok( $_, 'Gets dirty' ) foreach @x;

    is( $x,     21, 'value stays the same' );
    is( $x{k1}, 28, 'value stays the same' );
    is( $x{k2}, 35, 'value stays the same' );
    is( $x{k3}, 42, 'value stays the same' );
    is( $x{k4}, 49, 'value stays the same' );
    is( $x[0],  56, 'value stays the same' );
    is( $x[1],  63, 'value stays the same' );
    is( $x[2],  70, 'value stays the same' );
    is( $x[3],  77, 'value stays the same' );

    $x =~ /\A(\d+)\z/ or die;
    $x = $1;

    untainted_ok( $x, 'Reclean' );

    foreach my $value (values %x) {
        $value =~ /\A(\d+)\z/ or die;
        $value = $1;
    }

    untainted_ok( $x{$_}, 'Reclean' ) foreach keys %x;

    foreach my $element (@x) {
        $element =~ /\A(\d+)\z/ or die;
        $element = $1;
    }

    untainted_ok( $_, 'Reclean' ) foreach keys %x;

    is( $x,     21, 'value stays the same' );
    is( $x{k1}, 28, 'value stays the same' );
    is( $x{k2}, 35, 'value stays the same' );
    is( $x{k3}, 42, 'value stays the same' );
    is( $x{k4}, 49, 'value stays the same' );
    is( $x[0],  56, 'value stays the same' );
    is( $x[1],  63, 'value stays the same' );
    is( $x[2],  70, 'value stays the same' );
    is( $x[3],  77, 'value stays the same' );
}

TAINT_A_HASH_OBJECT: {
    {
        package My::ObjectHash;
        sub new { return bless {} => shift };
    }

    my $hash_object = My::ObjectHash->new;
    isa_ok( $hash_object, 'My::ObjectHash' );
    $hash_object->{value} = 84;

    untainted_ok( $hash_object->{value}, 'Starts clean' );
    taint_deeply( $hash_object );
    tainted_ok( $hash_object->{value}, 'Gets dirty' );
    is( $hash_object->{value}, 84, 'value stays the same' );

    $hash_object->{value} =~ /\A(\d+)\z/ or die;
    $hash_object->{value} = $1;

    untainted_ok( $hash_object->{value}, 'Reclean' );
    is( $hash_object->{value}, 84, 'value stays the same' );
    isa_ok( $hash_object, 'My::ObjectHash' );
}

TAINT_AN_ARRAY_OBJECT: {
    {
        package My::ObjectArray;
        sub new { return bless [] => shift };
    }

    my $array_object = My::ObjectArray->new;
    isa_ok( $array_object, 'My::ObjectArray' );
    $array_object->[0] = 84;

    untainted_ok( $array_object->[0], 'Starts clean' );
    taint_deeply( $array_object );
    tainted_ok( $array_object->[0], 'Gets dirty' );
    is( $array_object->[0], 84, 'value stays the same' );

    $array_object->[0] =~ /\A(\d+)\z/ or die;
    $array_object->[0] = $1;

    untainted_ok( $array_object->[0], 'Reclean' );
    is( $array_object->[0], 84, 'value stays the same' );
    isa_ok( $array_object, 'My::ObjectArray' );
}

TAINT_A_SCALAR_OBJECT: {
    {
        package My::ObjectScalar;
        sub new { my $scalar; return bless \$scalar => shift };
    }

    my $scalar_object = My::ObjectScalar->new;
    isa_ok( $scalar_object, 'My::ObjectScalar' );
    ${$scalar_object} = 84;

    untainted_ok( ${$scalar_object}, 'Starts clean' );
    taint_deeply( $scalar_object );
    tainted_ok( ${$scalar_object}, 'Gets dirty' );
    is( ${$scalar_object}, 84, 'value stays the same' );

    ${$scalar_object} =~ /\A(\d+)\z/ or die;
    ${$scalar_object} = $1;

    untainted_ok( ${$scalar_object}, 'Reclean' );
    is( ${$scalar_object}, 84, 'value stays the same' );
    isa_ok( $scalar_object, 'My::ObjectScalar' );
}

TAINT_A_REF: {
    {
        package My::ObjectRef;
        sub new {
            my $ref = \my %hash;;
            return bless \$ref, => shift;
         };
    }

    my $ref_object = My::ObjectRef->new;
    isa_ok( $ref_object, 'My::ObjectRef' );
    ${$ref_object}->{key} = 1;

    untainted_ok( ${$ref_object}->{key}, 'Starts clean' );
    taint_deeply( $ref_object );
    tainted_ok( ${$ref_object}->{key}, 'Gets dirty' );
    is( ${$ref_object}->{key}, 1, 'value stays the same' );

    ${$ref_object}->{key} =~ /\A(\d+)\z/ or die;
    ${$ref_object}->{key} = $1;

    untainted_ok( ${$ref_object}->{key}, 'Reclean' );
    is( ${$ref_object}->{key}, 1, 'value stays the same' );
    isa_ok( $ref_object, 'My::ObjectRef' );
}

TAINT_A_TIED_HASH: {
    {
        package My::TiedHash;

        use Tie::Hash;
        use base 'Tie::StdHash';
    }

    my $tied_hash_object = tie my %tied_hash, 'My::TiedHash';
    $tied_hash_object->{value} = 84;

    untainted_ok( $tied_hash_object->{value}, 'Starts clean' );
    taint_deeply( \%tied_hash );
    tainted_ok( $tied_hash_object->{value}, 'Gets dirty' );
    is( $tied_hash_object->{value}, 84, 'value stays the same' );

    $tied_hash_object->{value} =~ /\A(\d+)\z/ or die;
    $tied_hash_object->{value} = $1;

    untainted_ok( $tied_hash_object->{value}, 'Reclean' );
    is( $tied_hash_object->{value}, 84, 'value stays the same' );
}

TAINT_A_TIED_ARRAY: {
    {
        package My::TiedArray;

        use Tie::Array;
        use base 'Tie::StdArray';
    }

    my $tied_array_object = tie my @tied_array, 'My::TiedArray';

    $tied_array_object->[0] = 56;

    untainted_ok( $tied_array_object->[0], 'Starts clean' );
    taint_deeply( \@tied_array );
    tainted_ok( $tied_array_object->[0], 'Gets dirty' );
    is( $tied_array_object->[0], 56, 'value stays the same' );

    $tied_array_object->[0] =~ /\A(\d+)\z/ or die;
    $tied_array_object->[0] = $1;

    untainted_ok( $tied_array_object->[0], 'Reclean' );
    is( $tied_array_object->[0], 56, 'value stays the same' );
}

TAINT_A_TIED_SCALAR: {
    {
        package My::TiedScalar;

        use Tie::Scalar;
        use base 'Tie::StdScalar';
    }

    my $tied_scalar_object = tie my $tied_scalar, 'My::TiedScalar';

    ${$tied_scalar_object} = 63;

    untainted_ok( ${$tied_scalar_object}, 'Starts clean' );
    taint_deeply( \$tied_scalar );
    tainted_ok( ${$tied_scalar_object}, 'Gets dirty' );
    is( ${$tied_scalar_object}, 63, 'value stays the same' );

    ${$tied_scalar_object} =~ /\A(\d+)\z/ or die;
    ${$tied_scalar_object} = $1;

    untainted_ok( ${$tied_scalar_object}, 'Reclean' );
    is( ${$tied_scalar_object}, 63, 'value stays the same' );
}

TAINT_AN_OVERLOADED_OBJECT: {
    {
        package My::Overloaded;
        use base 'My::ObjectHash';
        use overload '""' => \&as_string;

        sub as_string {
            my $self = shift;
            return "%{$self}";
        }
    }

    my $overloaded_object = My::Overloaded->new;
    isa_ok( $overloaded_object, 'My::Overloaded' );
    $overloaded_object->{value} = 99;

    untainted_ok( $overloaded_object->{value}, 'Starts clean' );
    taint_deeply( $overloaded_object );
    tainted_ok( $overloaded_object->{value}, 'Gets dirty' );
    is( $overloaded_object->{value}, 99, 'value stays the same' );

    $overloaded_object->{value} =~ /\A(\d+)\z/ or die;
    $overloaded_object->{value} = $1;

    untainted_ok( $overloaded_object->{value}, 'Reclean' );
    is( $overloaded_object->{value}, 99, 'value stays the same' );
    isa_ok( $overloaded_object, 'My::Overloaded' );
}
