package WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST;

use Moo;

our $VERSION = '0.000021';

use List::AllUtils qw( any );
use MooX::HandlesVia;
use MooX::StrictConstructor;
use Types::Common::String qw( NonEmptyStr );
use Types::Standard qw( ArrayRef Bool );
use WebService::PayPal::PaymentsAdvanced::Error::IPVerification;

extends 'WebService::PayPal::PaymentsAdvanced::Response';

sub BUILD {
    my $self = shift;

    return
        if !$self->_has_ip_address
        || $self->_has_ip_address && $self->_ip_address_is_verified;

    WebService::PayPal::PaymentsAdvanced::Error::IPVerification->throw(
        message => $self->_ip_address . ' is not a verified PayPal address',
        ip_address => $self->_ip_address,
        params     => $self->params,
    );
}

has _ip_address => (
    is        => 'ro',
    isa       => NonEmptyStr,
    init_arg  => 'ip_address',
    required  => 0,
    predicate => '_has_ip_address',
);

has _ip_address_is_verified => (
    is       => 'ro',
    isa      => Bool,
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_ip_address_is_verified',
);

# Payments Advanced IPs listed at
# https://www.paypal-techsupport.com/app/answers/detail/a_id/883/kw/payflow%20Ip

has _ip_addresses => (
    is          => 'ro',
    isa         => ArrayRef,
    handles_via => 'Array',
    handles     => { _all_verified_ip_addresses => 'elements' },
    default     => sub {
        [ '173.0.81.1', '173.0.81.33', '66.211.170.66', '173.0.81.65' ];
    },
);

with(
    'WebService::PayPal::PaymentsAdvanced::Role::HasTender',
    'WebService::PayPal::PaymentsAdvanced::Role::HasTokens',
    'WebService::PayPal::PaymentsAdvanced::Role::HasTransactionTime',
);

sub _build_ip_address_is_verified {
    my $self = shift;

    return any { $_ eq $self->_ip_address } $self->_all_verified_ip_addresses;
}

1;

=pod

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST - Response object generated via Silent POST params

=head1 VERSION

version 0.000021

=head1 DESCRIPTION

This module provides an interface for extracting returned params from an
L<HTTP::Response> object.  You won't need to this module directly if you are
using L<PayPal::PaymentsAdvanced/get_response_from_silent_post>.

This module inherits from L<WebService::PayPal::PaymentsAdvanced::Response> and
includes the methods provided by
L<WebService::PayPal::PaymentsAdvanced::Role::HasTender>,
L<WebService::PayPal::PaymentsAdvanced::Role::HasTokens> and
L<WebService::PayPal::PaymentsAdvanced::Role::HasTransactionTime>.

=head1 OBJECT INSTANTIATION

The following parameters can be supplied to C<new()> when creating a new object.

=head2 Required Parameters

=head3 params

Returns a C<HashRef> of parameters which have been returned from PayPal via a
redirect or a silent POST.

=head2 Optional Parameters

=head3 ip_address

This is the IP address from which the PayPal params have been returned.  If
you provide an IP address, it will be validated against a list of known valid
IP addresses which have been provided by PayPal.  You are encouraged to
provide an IP in order to prevent spoofing.

This module will throw a
L<WebService::PayPal::PaymentsAdvanced::Error::IPVerification> exception if
the provided IP address cannot be validated.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# ABSTRACT: Response object generated via Silent POST params

