package cPanel::APIClient::Service;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

cPanel::APIClient::Service - base class for service objects

=head1 SYNOPSIS

See L<cPanel::APIClient> for example usage.

=head1 DESCRIPTION

This is a base class for objects that represent access to
a specific service with a specific configuration.

=cut

#----------------------------------------------------------------------

sub new {
    my ( $class, $transporter, $authn ) = @_;

    my %self = (
        transporter => $transporter,
        authn       => $authn,
    );

    return bless \%self, $class;
}

=head1 METHODS

=head2 $name = I<OBJ>->service_name()

Returns the name (e.g., C<cpanel>, C<whm>) of the service that I<OBJ>
accesses.

=cut

sub service_name {
    my ($self) = @_;

    my $name = ref($self);
    $name =~ s<.+::><>;

    return $name;
}

=head2 I<OBJ>->cancel( @ARGUMENTS )

Cancels an API call. If the configured transport mechanism
cannot cancel requests, an exception is thrown.

See your transport mechanism’s documentation for details about
what @ARGUMENTS should be and what this method returns.

=cut

sub cancel {
    my ( $self, @cancel_args ) = @_;

    my $transport_obj = $self->{'transporter'};

    if ( !$self->can('cancel') ) {
        my $transport_class = ref $transport_obj;
        die "$transport_class cannot cancel() a request!";
    }

    return $transport_obj->cancel(@cancel_args);
}

=head1 LICENSE

Copyright 2020 cPanel, L. L. C. All rights reserved. L<http://cpanel.net>

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

=cut

1;
