package Thrift::IDL::Definition;

=head1 NAME

Thrift::IDL::Definition

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Base>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Base);

=head1 METHODS

=head2 full_name

=cut

sub full_name {
    my $self = shift;

    if (! $self->can('name')) {
        die ref($self)."->full_name() doesn't make contextual sense";
    }
    if (! $self->{header}) {
        die ref($self)."->full_name() has no header to compute the full name from";
    }
    my @parts = split /\./, $self->name;
    if (int @parts > 1) {
        return $self->name;
    }
    else {
        return join '.', $self->{header}->basename || '', $self->name;
    }
}

=head2 local_name

Returns the last part of the full_name.

=cut

sub local_name {
    my $self = shift;
    if (! $self->can('name')) {
        die ref($self)."->local_name() doesn't make contextual sense";
    }
    my @parts = split /\./, $self->name;
    return $parts[ $#parts ];
}

1;
