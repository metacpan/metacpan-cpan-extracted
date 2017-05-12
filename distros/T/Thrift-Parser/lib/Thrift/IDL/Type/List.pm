package Thrift::IDL::Type::List;

=head1 NAME

Thrift::IDL::Type::List

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Type>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Type);
__PACKAGE__->mk_accessors(qw(val_type cpp_type));

=head1 METHODS

=head2 val_type

=head2 cpp_type

Scalar accessors

=cut

sub name { 'list' }

sub to_str {
    my ($self) = @_;
    return sprintf 'list (%s)', $self->val_type;
}

1;
