package WebService::PayPal::PaymentsAdvanced::Response::SecureToken;

use Moo;

use namespace::autoclean;

our $VERSION = '0.000022';

use feature qw( state );

extends 'WebService::PayPal::PaymentsAdvanced::Response';

use HTTP::Status qw( is_server_error );
use Type::Params qw( compile );
use Types::Standard qw( Bool CodeRef InstanceOf Int );
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

# Retry up to this number of times when encountering 5xx HTTP errors.
has retry_attempts => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

# Callback to call after encountering a 5xx HTTP error. We call this prior to
# retrying the request.
# Parameters to the callback: HTTP::Response from the request that generated a
# 5xx response.
has retry_callback => (
    is      => 'ro',
    isa     => CodeRef,
    default => sub {
        sub { }
    },
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

    my $res = $self->_make_http_request_with_retries($uri);

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

# Make an HTTP request to the given URI.
#
# Return the response if the request is successful. If the request fails with a
# 5xx error, retry. We retry up to the configured number of times. On
# encountering a non-5xx and non-success response, return the response
# immediately.
#
# Throw an error if we exhaust our retries.
sub _make_http_request_with_retries {
    my $self = shift;
    my $uri  = shift;

    my $res;

    # +1 so we always try at least once.
    for my $attempt ( 1 .. $self->retry_attempts + 1 ) {

        # For whatever reason on the PayPal side, HEAD isn't useful here.
        $res = $self->ua->get($uri);

        if ( $res->is_success ) {
            return $res;
        }

        # We want to support retries only if there is a 5xx error.
        if ( !is_server_error( $res->code ) ) {
            return $res;
        }

        # Don't call our callback if we won't be retrying. We'll throw an error.
        last if $attempt == $self->retry_attempts + 1;

        my $cb = $self->retry_callback;
        $cb->($res);
    }

    $self->_class_for('Error::HTTP')->throw_from_http_response(
              message_prefix => 'Made maximum number of HTTP requests. Tried '
            . ( $self->retry_attempts + 1 )
            . ' requests.',
        http_response => $res,
        request_uri   => $uri,
    );
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Response::SecureToken - Response class for creating secure tokens

=head1 VERSION

version 0.000022

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

=head2 retry_attempts

The number of HTTP retries to attempt if we encounter an error response. We
retry only when encountering HTTP 5xx responses.

=head2 retry_callback

A callback function we call prior to retrying the HTTP request to PayPal. We
call this function only when a retry will take place afterwards. Note we retry
only when there are retry attempts remaining, and only when encountering HTTP
5xx errors.

This callback is useful if you want to know about each request failure.
Consider a case where the first request failed, and then a retry request
succeeded. If you want to know about the first failure, you can provide a
callback that we call prior to the retry. In this scenario, you may want your
callback function to write a message to a log.

The callback will receive a single parameter, an HTTP::Response object. This is
the response to the request that failed.

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

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/webservice-paypal-paymentsadvanced/issues>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#ABSTRACT: Response class for creating secure tokens

