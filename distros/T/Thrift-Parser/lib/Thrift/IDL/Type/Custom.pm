package Thrift::IDL::Type::Custom;

=head1 NAME

Thrift::IDL::Type::Custom

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Type>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Type);
__PACKAGE__->mk_accessors(qw(name));

=head1 METHODS

=head2 name

Scalar accessor

=cut

sub to_str {
    return '"' . $_[0]->name .'"';
}

1;
