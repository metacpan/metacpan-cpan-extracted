package cPanel::APIClient::Response::UAPI;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use parent qw( cPanel::APIClient::Response );

use Call::Context;

sub succeeded {
    my ($self) = @_;

    return $self->{'status'} ? 1 : 0;
}

sub get_data {
    my ($self) = @_;

    die "Request failed; cannot get_data()!" if !$self->{'status'};

    return $self->{'data'};
}

sub get_errors_as_string {
    my ($self) = @_;

    return join( $/, $self->get_errors() );
}

sub get_errors {
    my ($self) = @_;

    return $self->_get_list('errors');
}

sub get_warnings {
    my ($self) = @_;

    return $self->_get_list('warnings');
}

sub get_messages {
    my ($self) = @_;

    return $self->_get_list('messages');
}

sub _get_list {
    my ( $self, $name ) = @_;

    Call::Context::must_be_list();

    return $self->{$name} ? @{ $self->{$name} } : ();
}

1;
