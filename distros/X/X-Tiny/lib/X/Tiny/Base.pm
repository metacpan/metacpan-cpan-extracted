package X::Tiny::Base;

use strict;
use warnings;

my %CALL_STACK;

my %PROPAGATIONS;

=encoding utf-8

=head1 NAME

X::Tiny::Base - super-light exception base class

=head1 SYNOPSIS

    package My::Module::X::Base;

    use parent qw( X::Tiny::Base );

    sub _new {
        my ($class, @args) = @_;

        ...
    }

    #Optionally, redefine this:
    sub get {
        my ($self, $attr_name) = @_;

        ...
    }

    #Optionally, redefine this:
    sub get_message { ... }

    #Optionally, redefine this:
    sub to_string { ... }

    #If you override this, be sure also to call the base method.
    sub DESTROY {
        my ($self) = @_;

        ...

        #vv This. Be sure to do this in your override method.
        $self->SUPER::DESTROY();
    }

=head1 DESCRIPTION

This base class can be subclassed into your distribution’s own
exception base class (e.g., C<My::Module::X::Base>), or you can treat it
as that base class itself (i.e., forgo C<My::Module::X::Base>).

C<X::Tiny::Base> serves two functions:

=over

=item 1) It is a useful set of defaults for overridable methods.

=item 2) Framework handling of L<overload> stringification behavior,
e.g., when an uncaught exception is printed.

=back

That stringification’s precise formatting is not defined; however, it
will always include, in addition to the exception’s main message:

=over

=item * A stack trace (including function arguments)

B<IMPORTANT:> For security purposes, take care not to expose any function
arguments that might contain sensitive information (e.g., passwords).

Note that, in pre-5.16 Perls, this writes to the C<@DB::args> global.
(That shouldn’t affect you, but it’s interaction with the environment, so
better documented than not.)

=item * Propagations

=back

There is currently no access provided in code to these; if that’s something
you’d like to have, let me know.

B<NOTE:> The overload stringification doesn’t seem to work as implemented in
Perl 5.8 or earlier. Perl 5.8 went end-of-life on 14 December 2008. Yeah.

=head1 SUBCLASS INTERFACE

The default behaviors seem pretty usable and desirable to me, but there may
be circumstances where someone wants other behaviors. Toward that end,
the following methods are meant to be overridden in subclasses:

=head2 I<CLASS>->OVERLOAD()

Returns a boolean to indicate whether this exception class should load
L<overload> as part of creating exceptions. If you don’t want the
memory overhead of L<overload>, then make this return 0. It returns 1
by default.

You might also make this 0 if, for example, you want to handle the
L<overload> behavior yourself. (But at that point, why use X::Tiny??)

=cut

use constant OVERLOAD => 1;

=head2 I<CLASS>->_new( MESSAGE, KEY1 => VALUE1, .. )

The main constructor. Whatever args this accepts are the args that
you should use to create exceptions via your L<X::Tiny> subclass’s
C<create()> method. You’re free to design whatever internal representation
you want for your class: hash reference, array reference, etc.

The default implementation accepts a string message and, optionally, a
list of key/value pairs. It is useful that subclasses of your base class
define their own MESSAGE, so all you’ll pass in is a specific piece of
information about this instance—e.g., an error code, a parameter name, etc.

=cut

sub _new {
    my ( $class, $string, %attrs ) = @_;

    return bless [ $string, \%attrs ], $class;
}

=head2 I<OBJ>->get_message()

Return the exception’s main MESSAGE.
This is useful for contexts where you want to encapsulate the error
internals from how you’re reporting them, e.g., for protocols.

=cut

sub get_message {
    return $_[0][0];
}

=head2 I<OBJ>->get( ATTRIBUTE_NAME )

Retrieves the value of an attribute.

=cut

sub get {
    my ( $self, $attr ) = @_;

    #Do we need to clone this? Could JSON suffice, or do we need Clone?
    return $self->[1]{$attr};
}

=head2 I<OBJ>->to_string()

Creates a simple string representation of your exception. The default
implementation contains the class and the MESSAGE given on instantiation.

This method’s return value should B<NOT> include a strack trace;
L<X::Tiny::Base>’s internals handle that one for you.

=cut

sub to_string {
    my ($self) = @_;

    return sprintf '%s: %s', ref($self), $self->[0];
}

#----------------------------------------------------------------------

=head1 DESTRUCTOR METHODS

If you define your own C<DESTROY()> method, make sure you also call
C<SUPER::DESTROY()>, or else you’ll get memory leaks as L<X::Tiny::Base>’s
internal tracking of object properties will never be cleared out.

=cut

sub DESTROY {
    my ($self) = @_;

    delete $CALL_STACK{$self->_get_strval()};
    delete $PROPAGATIONS{$self->_get_strval()};

    return;
}

#----------------------------------------------------------------------

sub new {
    my ($class, @args) = @_;

    $class->_check_overload() if $class->OVERLOAD();

    my $self = $class->_new(@args);

    $CALL_STACK{$self->_get_strval()} = [ _get_printable_call_stack(2) ];

    return $self;
}

#----------------------------------------------------------------------

sub PROPAGATE {
    my ($self, $file, $line) = @_;

    push @{ $PROPAGATIONS{$self->_get_strval()} }, [ $file, $line ];

    return $self;
}

my %_OVERLOADED;

sub _check_overload {
    my ( $class, $str ) = @_;

    #cf. eval_bug.readme
    my $eval_err = $@;

    $_OVERLOADED{$class} ||= eval qq{
        package $class;

        use overload (
            q<""> => __PACKAGE__->can('__spew'),
            bool => __PACKAGE__->can('_TRUE'),
        );

        1;
    };

    #Should never happen as long as overload.pm is available.
    warn if !$_OVERLOADED{$class};

    $@ = $eval_err;

    return;
}

sub _get_strval {
    my ($self) = @_;

    if ( overload->can('Overloaded') && overload::Overloaded($self) ) {
        return overload::StrVal($self);
    }

    return q<> . $self;
}

sub _get_printable_call_stack {
    my ($level) = @_;

    my @stack;

    package DB;

    #This local() causes pre-5.16 Perl to segfault.
    local @DB::args if $^V ge v5.16.0;

    while ( my @call = (caller $level)[3, 1, 2] ) {
        my ($pkg) = ($call[0] =~ m<(.+)::>);

        if (!$pkg || !$pkg->isa(__PACKAGE__)) {
            push @call, [ map { X::Tiny::Base::_arg_to_printable() } @DB::args ];  #need to copy the array
            push @stack, \@call;
        }

        $level++;
    }

    return @stack;
}

sub _arg_to_printable {

    return "$_" if ref;

    return 'undef' if !defined;

    my $copy;

    my $err = $@;

    # In order to avoid warn()ing on undefined values
    # (and to distinguish '' from undef) we now quote scalars.
    #
    # We also eval the assignment in case the item was already freed.
    #
    if ( eval { $copy = $_ } ) {
        $copy =~ s<'><\\'>g;
        substr($copy, 0, 0, q<'>);
        $copy .= q<'>;
    }
    else {
        $copy = '** argument not available anymore (already freed) **';
    }

    $@ = $err;

    return $copy;
}

use constant _TRUE => 1;

sub __spew {
    my ($self) = @_;

    my $spew = $self->to_string();

    if ( rindex($spew, $/) != (length($spew) - length($/)) ) {
        my ($args);
        $spew .= $/ . join( q<>, map {
            $args = join(', ', @{ $_->[3] } );
            "\t==> $_->[0]($args) (called in $_->[1] at line $_->[2])$/"
        } @{ $CALL_STACK{$self->_get_strval()} } );
    }

    if ( $PROPAGATIONS{ $self->_get_strval() } ) {
        $spew .= join( q<>, map { "\t...propagated at $_->[0], line $_->[1]$/" } @{ $PROPAGATIONS{$self->_get_strval()} } );
    }

    return $spew;
}

1;
