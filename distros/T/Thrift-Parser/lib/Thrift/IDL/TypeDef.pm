package Thrift::IDL::TypeDef;

=head1 NAME

Thrift::IDL::TypeDef

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Definition>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Definition);
__PACKAGE__->mk_accessors(qw(type name));

=head1 METHODS

=head2 type

=head2 name

Scalar accessors

=cut

sub to_str {
    my ($self) = @_;
    return sprintf 'typedef "%s" isa %s', $self->name, $self->type;
}

1;
