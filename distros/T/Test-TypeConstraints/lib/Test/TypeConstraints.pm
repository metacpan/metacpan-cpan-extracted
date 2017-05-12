package Test::TypeConstraints;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.07';
use Exporter 'import';
use Test::More;
use Test::Builder;
use Mouse::Util::TypeConstraints ();
use Scalar::Util ();
use Data::Dumper;

our @EXPORT = qw/ type_isa type_does type_isnt type_doesnt /;

sub type_isa {
    my ($got, $type, @rest) = @_;

    my $tc = _make_type_constraint(
        $type,
        \&Mouse::Util::TypeConstraints::find_or_create_isa_type_constraint
    );

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return _type_constraint_ok( $got, $tc, @rest );
}

sub type_does {
    my ($got, $type, @rest) = @_;

    my $tc = _make_type_constraint(
        $type,
        \&Mouse::Util::TypeConstraints::find_or_create_does_type_constraint
    );

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return _type_constraint_ok( $got, $tc, @rest );
}

sub type_isnt {
    my ($got, $type, @rest) = @_;

    my $tc = _make_type_constraint(
        $type,
        \&Mouse::Util::TypeConstraints::find_or_create_isa_type_constraint
    );

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return _type_constraint_not_ok( $got, $tc, @rest );
}

sub type_doesnt {
    my ($got, $type, @rest) = @_;

    my $tc = _make_type_constraint(
        $type,
        \&Mouse::Util::TypeConstraints::find_or_create_does_type_constraint
    );

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return _type_constraint_not_ok( $got, $tc, @rest );
}

sub _make_type_constraint {
    my($type, $make_constraint) = @_;

    # duck typing for (Mouse|Moose)::Meta::TypeConstraint
    if ( Scalar::Util::blessed($type) && $type->can("check") ) {
        return $type;
    } else {
        return $make_constraint->($type);
    }
}

sub _type_constraint_ok {
    my ($got, $tc, $test_name, %options) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $ret = ok(check_type($tc, $got, %options), $test_name || ( $tc->name . " types ok" ) )
        or diag(sprintf('type: "%s" expected. but got %s', $tc->name, Dumper($got)));

    return $ret;
}

sub _type_constraint_not_ok {
    my ($got, $tc, $test_name, %options) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $ret = ok(!check_type($tc, $got, %options), $test_name || ( $tc->name . " types ok" ) )
        or diag(sprintf('%s is not supposed to be of type "%s"', $tc->name, Dumper($got)));

    return $ret;
}

sub check_type {
    my ($tc, $value, %options) = @_;

    return 1 if $tc->check($value);
    if ( my $coerce_check = $options{coerce} ) {
        my $new_val = $tc->coerce($value);
        $coerce_check->($new_val) if ref $coerce_check;
        return 1 if $tc->check($new_val);
    }

    return 0;
}

1;
__END__

=head1 NAME

Test::TypeConstraints - testing whether some value is valid as (Moose|Mouse)::Meta::TypeConstraint

=head1 SYNOPSIS

  use Test::TypeConstraints qw(type_isa);

  type_isa($got, "ArrayRef[Int]", "type should be ArrayRef[Int]");

=head1 DESCRIPTION

Test::TypeConstraints is for testing whether some value is valid as (Moose|Mouse)::Meta::TypeConstraint.

=head1 METHODS

=head2 type_isa

    type_isa($value, $type);
    type_isa($value, $type, $test_name);
    type_isa($value, $type, $test_name, %options);

Performs a type check against the $value using the $type.

$type can be a class name, a Moose/Mouse type name,
Moose/Mouse::Meta::TypeConstraint object or
Moose/Mouse::Meta::TypeConstraint::Class object.

$test_name is the description of the test.  If not given, one will be provided.

%options control optional behaviors.  Its keys can be the following...

=head3 coerce

If true, coercion will be used when performing the type check.

If a code ref is given, it will be run and passed in the coerced value
for additional testing.

    type_isa $value, "Some::Class", "coerce to Some::Class", coerce => sub {
        isa_ok $_[0], "Some::Class";
        is $_[0]->value, $value;
    };

=head2 type_does

    type_does($value, $role);
    type_does($value, $role, $test_name);
    type_does($value, $role, $test_name, %options);

Tests that the $value does the $role.

Works like C<type_isa>, but for roles instead of classes and types.
The $value must have consumed the given $role.

=head2 type_isnt

=head2 type_doesnt

The opposites of C<type_isa> and C<type_does>.  They take the same
arguments and options.

Checks that the value is I<not> of the given type or role.

=head1 AUTHOR

Keiji Yoshimi E<lt>walf443 at gmail dot comE<gt>

=head1 THANKS TO

=over 

=item
schwern

=item
gfx

=item
tokuhirom

=back

=head1 SEE ALSO

L<Mouse::Util::TypeConstraints>, L<Moose::Util::TypeConstraints>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
