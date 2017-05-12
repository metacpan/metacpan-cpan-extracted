package Thrift::IDL::Field;

=head1 NAME

Thrift::IDL::Field

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Base>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Base);
__PACKAGE__->mk_accessors(qw(id optional type name default_value));

=head1 METHODS

=head2 id

=head2 optional

=head2 type

=head2 name

=head2 default_value

Scalar accessors

=cut

sub to_str {
    my ($self) = @_;

    return sprintf '%s (%s)',
        $self->name,
        join(', ',
            map { $_ .': '. $self->$_ }
            grep { defined $self->$_ }
            qw(id type optional default_value)
        );
}

1;
