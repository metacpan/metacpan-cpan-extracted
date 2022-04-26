use 5.008001;
use strict;
use warnings;

package Types::Self;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Exporter::Tiny qw();
our @ISA        = qw( Exporter::Tiny );
our @EXPORT     = qw( Self );
our @EXPORT_OK  = qw( is_Self assert_Self to_Self );

use Role::Hooks qw();
use Types::Standard qw( InstanceOf ConsumerOf );

sub _generate_Self {
	my ( $me, $name, $args, $globals ) = ( shift, @_ );

	return sub () {
		$me->_make_type_constraint( $globals ) unless defined $globals->{type};
		return $globals->{type};
	};
}

sub _generate_is_Self {
	my ( $me, $name, $args, $globals ) = ( shift, @_ );

	return sub ($) {
		my ( $value ) = @_;
		$me->_make_type_constraint( $globals ) unless defined $globals->{type};
		return $globals->{type}->check( $value );
	};
}

sub _generate_assert_Self {
	my ( $me, $name, $args, $globals ) = ( shift, @_ );

	return sub {
		my ( $value ) = @_;
		$me->_make_type_constraint( $globals ) unless defined $globals->{type};
		return $globals->{type}->assert_return( $value );
	};
}

sub _generate_to_Self {
	my ( $me, $name, $args, $globals ) = ( shift, @_ );

	return sub ($) {
		my ( $value ) = @_;
		$me->_make_type_constraint( $globals ) unless defined $globals->{type};
		return $globals->{type}->coerce( $value );
	};
}

sub _make_type_constraint {
	my ( $me, $globals ) = @_;
	return $globals->{type} if defined $globals->{type};

	my $caller = $globals->{into};
	my $is_role = 'Role::Hooks'->is_role( $caller );
	my $base = $is_role ? ConsumerOf : InstanceOf;

	$globals->{type} = $base->parameterize( $caller );
}

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Self - provides a "Self" type constraint, referring to the caller class or role

=head1 SYNOPSIS

  {
    package Cow;
    use Moo;
  }
  
  {
    package Horse;
    use Moo;
    use Types::Self;
    use Types::Standard qw( Str );
    
    has name   => ( is => 'ro', isa => Str  );
    has mother => ( is => 'ro', isa => Self );
    has father => ( is => 'ro', isa => Self );
  }
  
  my $alice = Horse->new( name => 'Alice' );
  my $bob   = Horse->new( name => 'Bob' );
  
  # Okay
  my $baby = Horse->new(
    name   => 'Baby',
    mother => $alice,
    father => $bob,
  );
  
  # Dies
  my $baby = Horse->new(
    name   => 'Baby',
    mother => Cow->new,
    father => $bob,
  );

=head1 DESCRIPTION

This module exports a C<Self> type constraint which consrtains values to be
blessed objects in the same class as the package it was imported into, or
blessed objects which consume the role it was imported into. It should do
the right thing with inheritance.

This module also exports C<is_Self>, which returns a boolean.

  package Marriage;
  use Moo::Role;
  use Types::Self qw( is_Self );
  
  has spouse => ( is => 'rwp', init_arg => undef );
  
  sub marry {
    my ( $me, $maybe_spouse ) = @_;
    if ( is_Self( $maybe_spouse ) ) {
      $me->_set_spouse( $maybe_spouse );
      $maybe_spouse->_set_spouse( $me );
    }
    else {
      warn "Cannot marry this!";
    }
    return $me;
  }

The module also exports C<assert_Self> which acts like C<is_Self> but instead
of returning a boolean, either lives or dies. This can be useful is you need
to check that the first argument to a function is a blessed object.

  sub connect {
    my ( $self ) = ( shift );
    assert_Self $self;  # dies if called as a class method
    $self->{connected} = 1;
    return $self;
  }

The module also exports C<to_Self> which will attempt to coerce other types
to the B<Self> type.

Only C<Self> is exported by default.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Types-Self>.

=head1 SEE ALSO

L<Types::Standard>, L<Type::Tiny::Manual>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
