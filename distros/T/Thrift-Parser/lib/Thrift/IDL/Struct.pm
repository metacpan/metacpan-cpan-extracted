package Thrift::IDL::Struct;

=head1 NAME

Thrift::IDL::Struct

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Definition>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Definition);
__PACKAGE__->mk_accessors(qw(name children));

=head1 METHODS

=head2 name

=head2 children

Scalar accessors

=head2 fields

Returns array ref of L<Thrift::IDL::Field> children

=head2 field_named ($name)

=head2 field_id ($id)

Returns object found in fields array with given key value

=cut

sub to_str {
    return $_[0]->name . ' ('
        . join (', ', map { '' . $_ } @{ $_[0]->fields })
        . ')';
}

sub fields {
    my $self = shift;
    $self->children_of_type('Thrift::IDL::Field');
}

sub field_named {
    my ($self, $name) = @_;
    $self->array_search($name, 'fields', 'name');
}

sub field_id {
    my ($self, $name) = @_;
    $self->array_search($name, 'fields', 'id');
}

sub setup {
    my $self = shift;
	$self->_setup('children');
}

1;
