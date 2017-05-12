package WebService::PayPal::PaymentsAdvanced::Response::SecureToken;

use Moo;

our $VERSION = '0.000021';

use feature qw( state );

extends 'WebService::PayPal::PaymentsAdvanced::Response';

use Type::Params qw( compile );
use Types::Standard qw( Bool InstanceOf );
use Types::URI qw( Uri );
use URI::QueryParam;
use Web::Scraper;
use WebService::PayPal::PaymentsAdvanced::Error::HTTP;
use WebService::PayPal::PaymentsAdvanced::Error::HostedForm;

has hosted_form_uri => (
    is       => 'lazy',
    isa      => Uri,
    init_arg => undef,
    builder  => '_build_hosted_form_uri',
);

has payflow_link_uri => (
    is       => 'ro',
    isa      => Uri,
    required => 1,
    coerce   => 1,
);

has validate_hosted_form_uri => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

with(
    'WebService::PayPal::PaymentsAdvanced::Role::ClassFor',
    'WebService::PayPal::PaymentsAdvanced::Role::HasTokens',
    'WebService::PayPal::PaymentsAdvanced::Role::HasUA',
);

sub _build_hosted_form_uri {
    my $self = shift;

    my $uri = $self->payflow_link_uri->clone;
    $uri->query_param( SECURETOKEN   => $self->secure_token, );
    $uri->query_param( SECURETOKENID => $self->secure_token_id, );

    return $uri unless $self->validate_hosted_form_uri;

    # For whatever reason on the PayPal side, HEAD isn't useful here.
    my $res = $self->ua->get($uri);

    unless ( $res->is_success ) {

        $self->_class_for('Error::HTTP')->throw_from_http_response(
            message_prefix => "hosted_form URI does not validate ($uri):",
            http_response  => $res,
            request_uri    => $uri,
        );

    }

    my $error_scraper = scraper {
        process( '.error', error => 'TEXT' );
    };

    my $scraped_text = $error_scraper->scrape($res);

    return $uri unless exists $scraped_text->{error};

    $self->_class_for('Error::HostedForm')->throw(
        message =>
            "hosted_form contains error message: $scraped_text->{error}",
        http_response => $res,
        http_status   => $res->code,
        request_uri   => $uri,
    );
}

1;

=pod

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Response::SecureToken - Response class for creating secure tokens

=head1 VERSION

version 0.000021

=head1 SYNOPSIS

    my $ppa = WebService::PayPal::PaymentsAdvanced->new( ... );
    my $response = $ppa->create_secure_token( ... );

=head1 DESCRIPTION

You should not create this response object directly.  It will be provided to
you via L<WebService::PayPal::PaymentsAdvanced/<create_secure_token>.

=head1 OPTIONS

=head2 payflow_link_uri

The URL for the PayflowLink web service.  Can be a mocked URL.

=head2 validate_hosted_form_uri

C<Bool> which indicates whether we should pre-fetch the hosted form and do some
error checking (recommended).

=head1 METHODS

This module inherits from L<WebService::PayPal::PaymentsAdvanced::Response>,
please see its documentation for a list of the methods which it provides..

=head2 hosted_form_uri

Returns a L<URI> object which you can use either to insert an iframe into your
pages or redirect the user to PayPal directly in order to make a payment.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(
        validate_hosted_form_uri => 1, ... );

    my $response = $payments->create_secure_token(...);
    my $uri      = $response->hosted_form_uri;

=head3 params

A C<HashRef> of parameters which have been returned by PayPal.

=head2 secure_token

Returns the PayPal SECURETOKEN param.

=head2 secure_token_id

Returns the PayPal SECURETOKENID param.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#ABSTRACT: Response class for creating secure tokens

