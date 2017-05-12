package Thrift::IDL::Namespace;

=head1 NAME

Thrift::IDL::Namespace

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Header>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Header);
__PACKAGE__->mk_accessors(qw(scope value));

=head1 METHODS

=head2 scope

=head2 value

Scalar accessors

=cut

1;
