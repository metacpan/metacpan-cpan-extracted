use strict;
package Tie::MooseObject;
BEGIN {
  $Tie::MooseObject::VERSION = '0.0001';
} # for Pod::Weaver
# ABSTRACT: a tied hash interface to Moose object attributes


use MooseX::Declare 0.33;

class Tie::MooseObject {
    use MooseX::Has::Sugar 0.0405;
    use MooseX::Types::Moose 0.12 qw( Bool Str HashRef CodeRef Object );
    use Moose::Util::TypeConstraints 1.03 qw( enum );
    use List::Util 1.23 qw( first );
    use Carp qw( croak );


    has '_reader' => ( isa => HashRef[CodeRef], ro, lazy_build );
    has '_writer' => ( isa => HashRef[CodeRef], ro, lazy_build );
    has '_predicate' => ( isa => HashRef[CodeRef], ro, lazy_build );


    has 'is' => ( isa => enum( [ qw(ro rw) ] ), default => 'ro', rw );


    has 'write_loop' => ( isa => Bool, default => 0, rw );


    has 'object' => ( isa => Object, ro, required );


    method BUILD {
        $self->TIEHASH;
    }

    method TIEHASH(ClassName|Object $self: @args )  {
        $self = $self->new( @args )
            unless ref $self;
        return $self;
    }

    method _build__reader() {
        return $self->_build_rw( 'read' );
    }

    method _build__writer() {
        return $self->_build_rw( 'write' );
    }

    method _build__predicate() {
        my $object = $self->object;
        my $meta = Class::MOP::Class->initialize( ref $object );
        my ( %predicate );
        for ( $meta->get_method_list ) {
            my $method = $meta->get_method( $_ );
            next unless $method->can( 'associated_attribute' );
            my $attr = $method->associated_attribute;
            my ( $predicate ) = ref( $attr->predicate ) ? %{ $attr->predicate } : $attr->predicate;
            if ( $predicate and $method->name eq $predicate ) {
                $predicate{ $predicate } = $method->body;
            }
        }
        return \%predicate;
    }

    method _build_rw( Str $type ) {
        my ( $has, $get ) = $type eq 'read'
            ? qw( has_read_method get_read_method )
            : qw( has_write_method get_write_method );
        my $meta = Class::MOP::Class->initialize( ref $self->object );
        my %return;
        for ( $meta->get_method_list ) {
            my $method = $meta->get_method( $_ );
            next unless $method->can( 'associated_attribute' );
            my $attr = $method->associated_attribute;
            if ( $attr->$has() && $method->name eq $attr->$get() ) {
                $return{ $method->name } = $method->body;
            }
        }
        return \%return;
    }


    method STORE( Str $key, Any $value ) {
        croak "Attempt to modify a readonly Moose tied hash"
            if $self->is eq 'ro';

        if ( exists $self->_writer->{$key} ) {
            $self->_writer->{$key}->( $self->object, $value );
            return $value;
        }
        else {
            croak "Invalid attempt to call write method $key on $self->object for Moose tied hash";
        }
    }


    method FETCH( Str $key ) {
        if ( exists $self->_reader->{$key} ) {
            return $self->_reader->{$key}->( $self->object );
        }
        croak "Invalid attempt to call read method $key on $self->object for Moose tied hash";
    }


    method FIRSTKEY {
        my $h = $self->_get_loop_hashref;
        my $a = scalar keys %{ $h };
        if ( wantarray ) {
            my ( $k, $v ) = each %{ $h };
            return ( $k, $v->( $self->object ) );
        }
        # else scalar or void context
        return each %{ $h };
    }

    method NEXTKEY {
        my $h = $self->_get_loop_hashref;
        if ( wantarray ) {
            my ( $k, $v ) = each %{ $h };
            return ( $k, $v->( $self->object ) );
        }
        # else scalar or void context
        return each %{ $h };
    }


    method SCALAR {
        return scalar( keys( %{ $self->_get_loop_hashref } ) );
    }


    method EXISTS( Str $key ) {
        return $self->_predicate->{$key}->( $self->object ) if exists $self->_predicate->{$key};
        return exists $self->_reader->{$key} if exists $self->_reader->{$key};
        return exists $self->_writer->{$key} if $self->is eq 'rw';
        return;
    }


    method DELETE( Str $key ) {
        croak "$self->DELETE not implemented";
    }

# override this method if you have some default for clearing the method hash values...
    method CLEAR  {
        croak "$self->CLEAR not implemented";
    }

    method _get_loop_hashref {
        return $self->write_loop
            ? $self->_writer
            : $self->_reader;
    }
}

1;



__END__
=pod

=head1 NAME

Tie::MooseObject - a tied hash interface to Moose object attributes

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    package Point;

    has 'x' => (
        is => 'rw',
        isa => 'Int',
        predicate => 'has_x',
        reader => 'get_x',
        writer => 'set_x'
    );
    has 'y' => ( isa => 'Int', is => 'rw' );

    my $p = new Point( x => 1, y => 20 );
    my %point;
    tie %point, 'Tie::MooseObject', { object => $p };

    $point{set_x} = 4;
    $point{y} = 20;
    print $p->get_x, "\n",
          $p->y, "\n";
    use Data::Dumper;
    print Dumper( \%point );

=head1 DESCRIPTION

This module is BETA software. It seems to work so far, but it is not well
tested. B< USE AT YOUR OWN RISK >.

B<NOTE>: This documentation assumes you already have knowledge of L<Moose> and Moose
attributes.

Tie::MooseObject allows you to tie a hash to a Moose object.  The tied hash
uses the object's attributes accessor methods as keys. The C<reader> accessor
method is the key for fetching from the tied hash, the C<writer> method is the
key for assigning.

This module does not support C<handles>. C<handles> is used to delegate methods
to the object stored in the attribute. There is no way to know if the delegation
is for an attribute accessor or to perform some task. In the future this may
be supported through explicit options.

=head1 ATTRIBUTES

=head2 C<is>

Expects a string of either C<ro> or C<rw>, If set to C<ro>, Tie::MooseObject
will not allow access to the C<writer> attribute methods. This means that
C<STORE> will fatal.

=head2 C<write_loop>

This tells Tie::MooseObject to use the C<writer> method names as the keys when
you call C<each()> or C<keys()>

=head2 C<object>

The object to C<tie()> to. Required.

=head1 METHODS

=head2 C<TIEHASH>

When using C<tie()>, you should pass in a hash or hash reference of
arguments as the last argument. These arguments are the same style
as a standard Moose constructor. See L</ATTRIBUTES> for a list of
possible and required arguments.

=head2 C<STORE>

Assignment to a key in the hash will call the C<writer> method by the same name
as the key. If you attempt to call this method on a read-only hash,
Tie::MooseObject will throw an error. Also, If you attempt to add a new value
to the tied hash a error will be thrown.

=head2 C<FETCH>

When fetching a value from the tied hash, the key should be the name of the
C<reader> attribute method. If you pass in a key which does not exist, an error
will be thrown.

=head2 C<FIRSTKEY>

=head2 C<NEXTKEY>

When looping, by default, the key will be the name of attributes C<reader>
method. If you specify C<write_loop> when constructing the tied hash, the key
will be the C<writer> method instead.

=head2 C<SCALAR>

In scalar context, by default, the number of C<reader> attribute methods are
returned. If you specified C<write_loop> when C<tie()>ing the hash, the number
of C<writer> attribute methods will be returned.

=head2 C<EXISTS>

If the key is the name of the attributes C<predicate> method, the value
returned by a call to this method is returned. If the key is the name of a
C<reader> method, true is returned. If the hash is C<rw> and the key is the
names of a C<writer> method, this returns true.

=head2 C<DELETE>

=head2 C<CLEAR>

These method are not implemented so do not attempt to call them.

=head1 AUTHOR

  Scott A. Beck <scottbeck@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Scott A. Beck <scottbeck@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

