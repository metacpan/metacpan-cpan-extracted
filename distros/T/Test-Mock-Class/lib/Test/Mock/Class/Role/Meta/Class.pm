#!/usr/bin/perl -c

package Test::Mock::Class::Role::Meta::Class;

=head1 NAME

Test::Mock::Class::Role::Meta::Class - Metaclass for mock class

=head1 DESCRIPTION

This role provides an API for defining and changing behavior of mock class.

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.0303';

use Moose::Role;


use Moose::Util;

use Symbol ();

use Test::Assert ':all';

use Exception::Base (
    '+ignore_package' => [__PACKAGE__],
);


=head1 ATTRIBUTES

=over

=item B<mock_base_object_role> : Str = "Test::Mock::Class::Role::Object"

Base object role for mock class.  The default is
L<Test::Mock::Class::Role::Object>.

=cut

has 'mock_base_object_role' => (
    is      => 'rw',
    default => 'Test::Mock::Class::Role::Object',
);

=item B<mock_ignore_methods_regexp> : RegexpRef = "/^(_?mock_|(can|DEMOLISHALL|DESTROY|DOES|does|isa|VERSION)$)/"

Regexp matches method names which are not created automatically for mock
class.

=cut

has 'mock_ignore_methods_regexp' => (
    is      => 'rw',
    default => sub { qr/^(_?mock_|(can|DEMOLISHALL|DESTROY|DOES|does|meta|isa|VERSION)$)/ },
);

=item B<mock_constructor_methods_regexp> : RegexpRef = "/^new$/"

Regexp matches method names which are constructors rather than normal methods.

=back

=cut

has 'mock_constructor_methods_regexp' => (
    is      => 'rw',
    default => sub { qr/^new$/ },
);


use namespace::clean -except => 'meta';


## no critic qw(RequireCheckingReturnValueOfEval)

=head1 CONSTRUCTORS

=over

=item B<create_mock_class>( I<name> : Str, :I<class> : Str, I<args> : Hash ) : Moose::Meta::Class

Creates new L<Moose::Meta::Class> object which represents named mock class.
It automatically adds all methods which exists in original class, except those
which matches C<mock_ignore_methods_regexp> attribute.

If C<new> method exists in original class, it is created as constructor.

The method takes additional arguments:

=over

=item class

Optional I<class> parameter is a name of original class and its methods will
be created for new mock class.

=item methods

List of additional methods to create.

=back

The constructor returns metaclass object.

  Test::Mock::Class->create_mock_class(
      'IO::File::Mock' => ( class => 'IO::File' )
  );

=cut

sub create_mock_class {
    my ($class, $name, %args) = @_;
    my $self = $class->create($name, %args);
    $self->_construct_mock_class(%args);
    return $self;
};


=item B<create_mock_anon_class>( :I<class> : Str, I<args> : Hash ) : Moose::Meta::Class

Creates new L<Moose::Meta::Class> object which represents anonymous mock
class.  Optional I<class> parameter is a name of original class and its
methods will be created for new mock class.

Anonymous classes are destroyed once the metaclass they are attached to goes
out of scope.

The constructor returns metaclass object.

  my $meta = Test::Mock::Class->create_mock_anon_class(
      class => 'File::Temp'
  );

=back

=cut

sub create_mock_anon_class {
    my ($class, %args) = @_;
    my $self = $class->create_anon_class(%args);
    $self->_construct_mock_class(%args);
    return $self;
};


=head1 METHODS

=over

=item B<add_mock_method>( I<method> : Str ) : Self

Adds new I<method> to mock class.  The behavior of this method can be changed
with C<mock_return> and other methods.

=cut

sub add_mock_method {
    my ($self, $method) = @_;
    $self->add_method( $method => sub {
        my $method_self = shift;
        return $method_self->mock_invoke($method, @_);
    } );
    return $self;
};


=item B<add_mock_constructor>( I<method> : Str ) : Self

Adds new constructor to mock class.  This is almost the same as
C<add_mock_method> but it returns new object rather than defined value.

The calls counter is set to C<1> for new object's constructor.

=cut

sub add_mock_constructor {
    my ($self, $constructor) = @_;
    $self->add_method( $constructor => sub {
        my $method_class = shift;
        $method_class->mock_invoke($constructor, @_) if blessed $method_class;
        my $new_object = $method_class->meta->new_object(@_);
        $new_object->mock_invoke($constructor, @_);
        return $new_object;
    } );
    return $self;
};


=item B<_construct_mock_class>( :I<class> : Str, :I<methods> : ArrayRef ) : Self

Constructs mock class based on original class.  Adds the same methods as in
original class.  If original class has C<new> method, the constructor with
this name is created.

=cut

sub _construct_mock_class {
    my ($self, %args) = @_;

    Moose::Util::apply_all_roles(
        $self,
        $self->mock_base_object_role,
    );

    $self->superclasses( $self->_get_mock_superclasses($args{class}) );

    my @methods = defined $args{methods} ? @{ $args{methods} } : ();

    my @mock_methods = do {
        my %uniq = map { $_ => 1 }
                   (
                       $self->get_all_method_names,
                       @methods,
                   );
        keys %uniq;
    };

    foreach my $method (@mock_methods) {
        if ($method =~ $self->mock_ignore_methods_regexp) {
            # ignore destructor and basic instrospection methods
        }
        elsif ($method =~ $self->mock_constructor_methods_regexp) {
            $self->add_mock_constructor($method);
        }
        else {
            $self->add_mock_method($method);
        };
    };

    return $self;
};


sub _get_mock_superclasses {
    my ($self, $class) = @_;

    return ('Moose::Object') unless defined $class;

    my @superclasses = (
        $class->can('meta')
        ? $class->meta->superclasses
        : @{ *{Symbol::qualify_to_ref('ISA', $class)} },
    );

    unshift @superclasses, 'Moose::Object'
        unless grep { $_ eq 'Moose::Object' } @superclasses;

    unshift @superclasses, $class;

    return @superclasses;
};


sub _get_mock_metaclasses {
    my ($self, $class) = @_;

    return () unless defined $class;
    return () unless $class->can('meta');

    return (
        attribute_metaclass => $class->meta->attribute_metaclass,
        instance_metaclass  => $class->meta->instance_metaclass,
        method_metaclass    => $class->meta->method_metaclass,
    );
};


sub _get_mock_metaclass_instance_roles {
    my ($self, $class) = @_;

    return () unless defined $class;
    return () unless $class->can('meta');

    my $metaclass_instance = $class->meta->get_meta_instance->meta;

    return () unless $metaclass_instance->can('roles');

    return map { $_->name }
           @{ $metaclass_instance->roles };
};


1;


=back

=begin umlwiki

= Class Diagram =

[                                    <<role>>
                        Test::Mock::Class::Role::Meta::Class
 ------------------------------------------------------------------------------
 +mock_base_object_role = "Test::Mock::Class::Role::Object"
 +mock_ignore_methods_regexp : RegexpRef = "/^(can|DEMOLISHALL|DESTROY|DOES|does|isa|VERSION)$/"
 +mock_constructor_methods_regexp : RegexpRef = "/^new$/"
 ------------------------------------------------------------------------------
 +create_mock_class( name : Str, :class : Str, args : Hash ) : Moose::Meta::Class
 +create_mock_anon_class( :class : Str, args : Hash ) : Moose::Meta::Class
 +add_mock_method( method : Str ) : Self
 +add_mock_constructor( method : Str ) : Self
                                                                               ]

=end umlwiki

=head1 SEE ALSO

L<Test::Mock::Class>.

=head1 BUGS

The API is not stable yet and can be changed in future.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Based on SimpleTest, an open source unit test framework for the PHP
programming language, created by Marcus Baker, Jason Sweat, Travis Swicegood,
Perrick Penet and Edward Z. Yang.

Copyright (c) 2009, 2010 Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under GNU Lesser General Public License.
