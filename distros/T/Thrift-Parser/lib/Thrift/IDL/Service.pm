package Thrift::IDL::Service;

=head1 NAME

Thrift::IDL::Service

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Definition>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Definition);
__PACKAGE__->mk_accessors(qw(name extends children));

=head1 METHODS

=head2 name

=head2 extends

=head2 children

Scalar accessors

=head2 methods

Returns array ref of all L<Thrift::IDL::Method> children

=cut

sub methods {
    my $self = shift;
    $self->children_of_type('Thrift::IDL::Method');
}

=head2 method_named ($name)

Return named method

=cut

sub method_named {
    my ($self, $name) = @_;
    $self->array_search($name, 'methods', 'name');
}

sub to_str {
    my $self = shift;
    return $self->name . ($self->extends ? ' (extends ' . $self->extends . ') ' : '');
}

1;
