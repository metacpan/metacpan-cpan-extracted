package cPanel::APIClient::Response::UAPI;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

cPanel::APIClient::Response::UAPI

=head1 SYNOPSIS

See L<cPanel::APIClient::Service::cpanel>.

=head1 DESCRIPTION

This class represents a response to a cPanel UAPI request.

=cut

#----------------------------------------------------------------------

use parent qw( cPanel::APIClient::Response );

use Call::Context;

#----------------------------------------------------------------------

=head1 METHODS

=head2 $yn = I<OBJ>->succeeded()

Returns a boolean that indicates whether the request succeeded.

=cut

sub succeeded {
    my ($self) = @_;

    return $self->{'status'} ? 1 : 0;
}

=head2 $scalar = I<OBJ>->get_data()

Returns the response’s payload. If that payload is a structure,
then a reference to that structure is returned.

=cut

sub get_data {
    my ($self) = @_;

    die "Request failed; cannot get_data()!" if !$self->{'status'};

    return $self->{'data'};
}

=head2 $str = I<OBJ>->get_errors_as_string()

Returns a single string with all of the response’s errors concatenated.

=cut

sub get_errors_as_string {
    my ($self) = @_;

    return join( $/, $self->get_errors() );
}

=head2 @errs = I<OBJ>->get_errors()

Returns a list of all the response’s errors.

Must be called in list context.

=cut

sub get_errors {
    my ($self) = @_;

    return $self->_get_list('errors');
}

=head2 @warnings = I<OBJ>->get_warnings()

Like C<get_errors()> but returns warnings.

=cut

sub get_warnings {
    my ($self) = @_;

    return $self->_get_list('warnings');
}

=head2 @messages = I<OBJ>->get_messages()

Like C<get_errors()> but returns informational messages.

=cut

sub get_messages {
    my ($self) = @_;

    return $self->_get_list('messages');
}

#----------------------------------------------------------------------

sub _get_list {
    my ( $self, $name ) = @_;

    Call::Context::must_be_list();

    return $self->{$name} ? @{ $self->{$name} } : ();
}

=head1 LICENSE

Copyright 2020 cPanel, L. L. C. All rights reserved. L<http://cpanel.net>

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

=cut

1;
