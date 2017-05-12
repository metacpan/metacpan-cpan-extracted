package Thrift::IDL::Enum;

=head1 NAME

Thrift::IDL::Enum

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Definition>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Definition);
__PACKAGE__->mk_accessors(qw(name values));

=head1 METHODS

=head2 name

=head2 values

Scalar accessors

=head2 numbered_values

Numbering the Enum is optional in the Thrift spec.  Calling this method will assign incremented numbers to each value (if they have no number)

=cut

sub numbered_values {
    my $self = shift;

    my $last_value = -1;
    foreach my $value_pair (@{ $self->values }) {
        if (! defined $value_pair->[1]) {
            $value_pair->[1] = ++$last_value;
        }
        else {
            $last_value = $value_pair->[1];
        }
    }

    return $self->values;
}

=head2 value_named

Return the value (number) with the given name

=cut

sub value_named {
    my ($self, $name) = @_;
    foreach my $value_pair (@{ $self->numbered_values }) {
        return $value_pair->[1] if $value_pair->[0] eq $name;
    }
    return;
}

=head2 value_id_name

Return the name for a given value (number)

=cut

sub value_id_name {
    my ($self, $id) = @_;
    foreach my $value_pair (@{ $self->numbered_values }) {
        return $value_pair->[0] if $value_pair->[1] == $id;
    }
    return;
}

1;
