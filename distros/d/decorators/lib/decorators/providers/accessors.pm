package decorators::providers::accessors;
# ABSTRACT: A set of decorators to generate accessor methods

use strict;
use warnings;

use decorators ':for_providers';

use Carp      ();
use MOP::Util ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub ro : Decorator : CreateMethod {
    my ( $meta, $method, @args ) = @_;

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        if ( $args[0] eq '_' ) {
            $slot_name = '_'.(($method_name =~ /^get_(.*)$/)[0] || $method_name);
        }
        else {
            $slot_name = shift @args;
        }
    }
    else {
        if ( $method_name =~ /^get_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::confess('Unable to build `ro` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub {
        Carp::confess("Cannot assign to `$slot_name`, it is a readonly") if scalar @_ != 1;
        $_[0]->{ $slot_name };
    });
}

sub rw : Decorator : CreateMethod {
    my ( $meta, $method, @args ) = @_;

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        if ( $args[0] eq '_' ) {
            $slot_name = '_'.$method_name;
        }
        else {
            $slot_name = shift @args;
        }
    }
    else {
        $slot_name = $method_name;
    }

    Carp::confess('Unable to build `rw` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because class is immutable.')
        if ($meta->name)->isa('UNIVERSAL::Object::Immutable');

    Carp::confess('Unable to build `rw` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub {
        $_[0]->{ $slot_name } = $_[1] if scalar( @_ ) > 1;
        $_[0]->{ $slot_name };
    });
}

sub wo : Decorator : CreateMethod {
    my ( $meta, $method, @args ) = @_;

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        if ( $args[0] eq '_' ) {
            $slot_name = '_'.(($method_name =~ /^set_(.*)$/)[0] || $method_name);
        }
        else {
            $slot_name = shift @args;
        }
    }
    else {
        if ( $method_name =~ /^set_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::confess('Unable to build `wo` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because class is immutable.')
        if ($meta->name)->isa('UNIVERSAL::Object::Immutable');

    Carp::confess('Unable to build `wo` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub {
        Carp::confess("You must supply a value to write to `$slot_name`") if scalar(@_) < 1;
        $_[0]->{ $slot_name } = $_[1];
    });
}

sub predicate : Decorator : CreateMethod {
    my ( $meta, $method, @args ) = @_;

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        if ( $args[0] eq '_' ) {
            $slot_name = '_'.(($method_name =~ /^has_(.*)$/)[0] || $method_name);
        }
        else {
            $slot_name = shift @args;
        }
    }
    else {
        if ( $method_name =~ /^has_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::confess('Unable to build predicate for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub { defined $_[0]->{ $slot_name } } );
}

sub clearer : Decorator : CreateMethod {
    my ( $meta, $method, @args ) = @_;

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        if ( $args[0] eq '_' ) {
            $slot_name = '_'.(($method_name =~ /^clear_(.*)$/)[0] || $method_name);
        }
        else {
            $slot_name = shift @args;
        }
    }
    else {
        if ( $method_name =~ /^clear_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::confess('Unable to build `clearer` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because class is immutable.')
        if ($meta->name)->isa('UNIVERSAL::Object::Immutable');

    Carp::confess('Unable to build `clearer` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub { undef $_[0]->{ $slot_name } } );
}


1;

__END__

=pod

=head1 NAME

decorators::providers::accessors - A set of decorators to generate accessor methods

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use decorators ':accessors';

  sub foo       : ro;      # infer the 'foo' slot name
  sub get_foo   : ro;      # infer the 'foo' slot name ignoring the 'get_'
  sub test_zero : ro(foo); # specify the 'foo' slot name explcitly

  sub bar     : rw;        # infer the 'bar' slot name
  sub rw_bar  : rw(bar);   # specity the 'bar' slot name explcitly
  sub set_bar : wo;        # infer the 'bar' name ignoring the 'set_'

  sub _baz    : ro;        # infer the '_baz' name
  sub baz     : rw(_);     # infer the private slot name (prefix with '_')
  sub set_baz : wo(_);     # infer the private slot name (prefix with '_') ignoring the 'set_'
  sub get_baz : ro(_);     # infer the private slot name (prefix with '_') ignoring the 'get_'

=head1 DESCRIPTION

=over 4

=item C<ro( ?$slot_name )>

This will generate a simple read-only accessor for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method that the trait is being applied to.

    sub foo : ro;
    sub foo : ro(_bar);

If the C<$slot_name> is simply an underscore (C<_>) then this
decorator will assume the slot name is the same name as the subroutine
only with an underscore prefix. This means that this:

    sub foo : ro(_);

Is the equivalent of writing this:

    sub foo : ro(_foo);

If the method name is prefixed with C<get_>, then this trait will
infer that the slot name intended is the remainder of the method's
name, minus the C<get_> prefix, such that this:

    sub get_foo : ro;

Is the equivalent of writing this:

    sub get_foo : ro(foo);

=item C<rw( ?$slot_name )>

This will generate a simple read-write accessor for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method that the trait is being applied to.

    sub foo : rw;
    sub foo : rw(_foo);

If the C<$slot_name> is simply an underscore (C<_>) then this
decorator will assume the slot name is the same name as the subroutine
only with an underscore prefix. This means that this:

    sub foo : rw(_);

Is the equivalent of writing this:

    sub foo : rw(_foo);

If the method name is prefixed with C<set_>, then this trait will
infer that the slot name intended is the remainder of the method's
name, minus the C<set_> prefix, such that this:

    sub set_foo : ro;

Is the equivalent of writing this:

    sub set_foo : ro(foo);

=item C<wo( ?$slot_name )>

This will generate a simple write-only accessor for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method that the trait is being applied to.

    sub foo : wo;
    sub foo : wo(_foo);

If the C<$slot_name> is simply an underscore (C<_>) then this
decorator will assume the slot name is the same name as the subroutine
only with an underscore prefix. This means that this:

    sub foo : wo(_);

Is the equivalent of writing this:

    sub foo : wo(_foo);

If the method name is prefixed with C<set_>, then this trait will
infer that the slot name intended is the remainder of the method's
name, minus the C<set_> prefix, such that this:

    sub set_foo : wo;

Is the equivalent of writing this:

    sub set_foo : wo(foo);

=item C<predicate( ?$slot_name )>

This will generate a simple predicate method for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method that the trait is being applied to.

    sub foo : predicate;
    sub foo : predicate(_foo);

If the C<$slot_name> is simply an underscore (C<_>) then this
decorator will assume the slot name is the same name as the subroutine
only with an underscore prefix. This means that this:

    sub foo : predicate(_);

Is the equivalent of writing this:

    sub foo : predicate(_foo);

If the method name is prefixed with C<has_>, then this trait will
infer that the slot name intended is the remainder of the method's
name, minus the C<has_> prefix, such that this:

    sub has_foo : predicate;

Is the equivalent of writing this:

    sub has_foo : predicate(foo);

=item C<clearer( ?$slot_name )>

This will generate a simple clearing method for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method that the trait is being applied to.

    sub foo : clearer;
    sub foo : clearer(_foo);

If the C<$slot_name> is simply an underscore (C<_>) then this
decorator will assume the slot name is the same name as the subroutine
only with an underscore prefix. This means that this:

    sub foo : clearer(_);

Is the equivalent of writing this:

    sub foo : clearer(_foo);

If the method name is prefixed with C<clear_>, then this trait will
infer that the slot name intended is the remainder of the method's
name, minus the C<clear_> prefix, such that this:

    sub clear_foo : clearer;

Is the equivalent of writing this:

    sub clear_foo : clearer(foo);

=back

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
