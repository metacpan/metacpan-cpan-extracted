package Thrift::IDL::Constant;

=head1 NAME

Thrift::IDL::Constant

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Definition>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Definition);
__PACKAGE__->mk_accessors(qw(type name value));

=head1 METHODS

=head2 type

=head2 name

=head2 value

Scalar accessors

=cut

1;
