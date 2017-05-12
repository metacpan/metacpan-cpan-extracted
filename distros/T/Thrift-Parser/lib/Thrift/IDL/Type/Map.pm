package Thrift::IDL::Type::Map;

=head1 NAME

Thrift::IDL::Type::Map

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Type>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Type);
__PACKAGE__->mk_accessors(qw(key_type val_type cpp_type));

=head1 METHODS

=head2 key_type

=head2 val_type

=head2 cpp_type

Scalar accessors

=cut

sub name { 'map' }

sub to_str {
    my ($self) = @_;
    return sprintf 'map (%s => %s)', $self->key_type, $self->val_type;
}

1;
