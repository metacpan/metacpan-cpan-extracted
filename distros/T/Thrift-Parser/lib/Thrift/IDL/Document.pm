package Thrift::IDL::Document;

=head1 NAME

Thrift::IDL::Document

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Base>.

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Base);
__PACKAGE__->mk_accessors(qw(children headers));

=head1 METHODS

=head2 children

=head2 headers

Scalar accessors

=head2 services

=head2 comments

=head2 typedefs

=head2 enums

=head2 structs

Returns array ref of children of named type

=head2 service_named ($name)

=head2 typedef_named ($name)

=head2 struct_named ($name)

=head2 object_named ($name)

=head2 object_full_named ($name)

Returns object found in named array with given key value

=cut

sub services {
    my $self = shift;
    $self->children_of_type('Thrift::IDL::Service');
}

sub service_named {
    my ($self, $name) = @_;
    $self->array_search($name, 'services', 'name');
}

sub comments {
    my $self = shift;
    $self->children_of_type('Thrift::IDL::Comment');
}

sub typedefs {
    my $self = shift;
    $self->children_of_type('Thrift::IDL::TypeDef');
}

sub typedef_named {
    my ($self, $name) = @_;
    $self->array_search($name, 'typedefs', 'name');
}

sub enums {
    my $self = shift;
    $self->children_of_type('Thrift::IDL::Enum');
}

sub structs {
    my $self = shift;
    $self->children_of_type('Thrift::IDL::Struct');
}

sub struct_named {
    my ($self, $name) = @_;
    $self->array_search($name, 'structs', 'name');
}

sub objects {
    my $self = shift;
    return [ @{ $self->structs }, @{ $self->typedefs }, @{ $self->services }, @{ $self->enums } ];
}

sub object_named {
    my ($self, $name) = @_;
    $self->array_search($name, 'objects', 'name');
}

sub object_full_named {
    my ($self, $full_name) = @_;
    $self->array_search($full_name, 'objects', 'full_name');
}

1;
