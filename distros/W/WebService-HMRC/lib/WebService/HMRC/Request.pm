package WebService::HMRC::Request;

use 5.006;
use Carp;
use JSON::MaybeXS qw(encode_json);
use LWP::UserAgent;
use Moose;
use namespace::autoclean;
use URI;
use WebService::HMRC::Response;


=head1 NAME

WebService::HMRC::Request - Base class for accessing the UK HMRC MTD API

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use WebService::HMRC::Request;
    my $r = WebService::HMRC::Request->new({
        base_url    => 'https://test-api.service.hmrc.gov.uk/',
        api_version => '1.0',
    });

    # get from open endpoint
    my $response = $r->get_endpoint({
        endpoint => '/hello/world',
    });
    print $response->data->{message} if $response->is_success;

    # get from application-restricted endpoint
    $r->auth->server_token('MY_SERVER_TOKEN');
    my $response = $r->get_endpoint({
        endpoint => '/hello/application',
        auth_type => 'application',
    });
    print $response->data->{message} if $response->is_success;
   
    # get from user-restricted endpoint
    $r->auth->access_token('MY_ACCESS_TOKEN');
    my $response = $r->get_endpoint({
        endpoint => '/hello/user',
        auth_type => 'user',
    });
    print $response->data->{message} if $response->is_success;
    
    # post data as json to an application-restricted endpoint
    my $data = {serviceNames => ['mtd-vat']};
    my $response = $r->post_endpoint_json({
        endpoint => '/create-test-user/organisations',
        data => $data,
        auth_type => 'application',
    });
    print $response->data->{userId} if $response->is_success;

=head1 DESCRIPTION

This is part of the L<WebService::HMRC> suite of Perl modules for
interacting with the UK's HMRC Making Tax Digital APIs.

This is a base class for making requests to the UK's HMRC Making Tax Digital
API. It is usually inherited by other higher-level classes, but can be
used directly.

This module provides methods for calling api endpoints, mapping their response
into a standard class and decoding their JSON payload. It also provides a
LWP::UserAgent with appropriate headers set and a lower-level method for
constructing api endpoint urls.

Note that access to restricted api endpoints requires application or user
credentials issued by HMRC.

=head1 INSTALLATION AND TESTING

See documentation for L<WebService::HMRC>.

=head1 PROPERTIES

=head2 auth

A WebService::HMRC::Authenticate object reference providing credentials and
tokens required to access protected endpoints. If not specified, an empty
WebService::HMRC::Authenticate will be created by default.

=cut

has auth => (
    is => 'rw',
    isa => 'WebService::HMRC::Authenticate',
    predicate => 'has_auth',
    lazy => 1,
    builder => '_build_auth',
);

=head2 base_url

Base url used for calls to the HMRC "Making Tax Digital" API. Defaults to test
url `https://test-api.service.hmrc.gov.uk/` if not specified.

See:
L<https://developer.service.hmrc.gov.uk/api-documentation/docs/reference-guide>

=cut

has base_url => (
    is => 'rw',
    isa => 'Str',
    default => 'https://test-api.service.hmrc.gov.uk/',
);

=head2 api_version

Read-only property which defines the API version in use by this module as a string.
Defaults to `1.0` if not specified.

See:
L<https://developer.service.hmrc.gov.uk/api-documentation/docs/reference-guide#versioning>

=cut

has api_version => (
    is => 'ro',
    isa => 'Str',
    default => '1.0',
);

=head2 ua

Read-only property representing a LWP::UserAgent object used to perform the
api calls. This will be created by default, but an alternative LWP::UserAgent
object may be provided instead, providing an appropriate default 'Accept'
header is configured.

=cut

has ua => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    lazy => 1,
    builder => '_build_ua',
);


=head1 METHODS

=head2 endpoint_url($endpoint)

Combine the given api endpoint (for example `/hello/world`) with
the api's base_url, returning a complete endpoint url.

Returns a URI object, which evaluates to a plain url in string
context.

=cut

sub endpoint_url {

    my $self = shift;
    my $endpoint = shift;

    # endpoint paramater is mandatory
    defined $endpoint or croak 'endpoint is undefined';

    # Strip any leading slash from the endpoint, which would otherwise
    # cause it to be interpreted as an absolute path, stripping any path
    # component from the base_url.
    #
    # When constructing an endpoint url, the full base_url is used,
    # including any path component.
    $endpoint =~ s|^/||;

    return URI->new_abs($endpoint, $self->base_url);
}


=head2 get_endpoint({ endpoint => $endpoint, [auth_type => $auth_type,] [parameters => \%params,] [headers => \@headers] })

Retrieve a response from an HMRC Making Tax Digital api endpoint, using
http get. Authorisation headers appropriate to the specified authorisation
type are added to the request.

Returns a WebService::HMRC::Response object reference.

=head3 Parameters:

=over

=item endpoint

Mandatory parameter specifying the endpoint to be accessed, for example
'/hello/world'. Combined with base_url to build a fully-qualified url.

=item auth_type

Optional parameter. If specified, must be one of 'open', 'user', or
'application', corresponding to the different types of authentication
used by HMRC MTD apis. If not specified, or undef, defaults to 'open'.

=item parameters

Optional parameter. A hashref containing query parameters and their
associated value to be appended to the endpoint url. 

=item headers

Optional parameter. An array of key/value pairs send as request headers in
addition to the default `Accept` header.

=back

=cut

sub get_endpoint {

    my ($self, $args) = @_;
    $args->{auth_type} ||= 'open';
    my $uri = $self->endpoint_url($args->{endpoint});
    my @headers;

    # Add authentication headers
    if($args->{auth_type} eq 'application') {
        $self->auth->has_server_token
            or croak 'auth->server_token is not defined';
        push @headers, 'Authorization' => 'Bearer ' . $self->auth->server_token;
    }
    elsif($args->{auth_type} eq 'user') {
        $self->auth->has_access_token
            or croak 'auth->access_token is not defined';
        push @headers, 'Authorization' => 'Bearer ' . $self->auth->access_token;
    }

    # Add optional query parameters
    if($args->{parameters}) {
        $uri->query_form($args->{parameters});
    }

    # Add optional request headers
    if($args->{headers}) {
        push @headers, @{$args->{headers}};
    }

    # Query server
    my $result = $self->ua->get(
        $uri,
        @headers
    );
    my $response = WebService::HMRC::Response->new({ http => $result });

    unless($response->is_success) {
        $self->_display_response_errors($response);
    }

    return $response;
}


=head2 post_endpoint_json({ endpoint => $endpoint, data => $ref, [auth_type => $auth_type,] [headers => \@headers] })

Post data encoded as json to an HMRC Making Tax Digital api endpoint.

Authorisation headers appropriate to the specified authorisation
type are added to the request.

Returns a WebService::HMRC::Response object reference.

=head3 Parameters:

=over

=item endpoint

Required parameter specifying the endpoint to be accessed, for example
'/hello/world'. Combined with base_url to build a fully-qualified url.

=item data

Required parameter. Reference to a perl data structure, either a hashref
or an arrayref, which is encoded to json for submission.

=item auth_type

Optional parameter. If specified, must be one of 'open', 'user', or
'application', corresponding to the different types of authentication
used by HMRC MTD apis. If not specified, or undef, defaults to 'open'.

=item headers

Optional parameter. An array of key/value pairs send as request headers in
addition to the default `Accept` header.

=back

=cut

sub post_endpoint_json {

    my ($self, $args) = @_;
    $args->{auth_type} ||= 'open';

    $args->{data} && ref $args->{data}
        or croak 'data parameter is missing or not a reference';

    my $uri = $self->endpoint_url($args->{endpoint});
    my @headers = (
        'Content-Type' => 'application/json',
    );
    my $body = encode_json($args->{data});

    # Add authentication headers
    if($args->{auth_type} eq 'application') {
        $self->auth->has_server_token
            or croak 'auth->server_token is not defined';
        push @headers, 'Authorization' => 'Bearer ' . $self->auth->server_token;
    }
    elsif($args->{auth_type} eq 'user') {
        $self->auth->has_access_token
            or croak 'auth->access_token is not defined';
        push @headers, 'Authorization' => 'Bearer ' . $self->auth->access_token;
    }

    # Add optional request headers
    if($args->{headers}) {
        push @headers, @{$args->{headers}};
    }

    # Query server
    my $result = $self->ua->post(
        $uri,
        @headers,
        Content => $body,
    );
    my $response = WebService::HMRC::Response->new({ http => $result });

    unless($response->is_success) {
        $self->_display_response_errors($response);
    }

    return $response;
}



# PRIVATE METHODS

# _build_ua()
# Returns a LWP::UserAgent object with a default `Accept` header
# defined, specifying the api version in use.
# Called as a Moose lazy builder.

sub _build_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new();

    # Accept header defines the API version in use
    $ua->default_header(
        'Accept' => 'application/vnd.hmrc.' . $self->api_version . '+json'
    );

    # Trailing space causes the default libwww user agent to be appended
    $ua->agent("WebService-HMRC-Request/$VERSION ");
    return $ua;
}

# _build_auth()
# Returns an empty WebService::HMRC::Authenticate object.
# Called as a Moose lazy builder.

sub _build_auth {
    my $self = shift;
    require WebService::HMRC::Authenticate;
    return WebService::HMRC::Authenticate->new();
}

# _display_response_errors($response)
# Given a WebService::HMRC::Response object, carp an error
# message including the http status line and any 'message'
# or 'code' values within the response data. Returns nothing.

sub _display_response_errors {

    my $self = shift;
    my $response = shift;

    carp 'Error calling api endpoint: ' . $response->http->status_line;
    carp 'code: ' . $response->data->{code} if $response->data->{code};
    carp 'message: ' . $response->data->{message} if $response->data->{message};

    return;
}


=head1 AUTHOR

Nick Prater <nick@npbroadcast.com>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-webservice-hmrc at rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-HMRC>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::HMRC::Request


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-HMRC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-HMRC>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-HMRC/>

=back

=head1 ACKNOWLEDGEMENTS

This module was originally developed for use as part of the
L<LedgerSMB|https://ledgersmb.org/> open source accounting software.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Nick Prater, NP Broadcast Limited.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

__PACKAGE__->meta->make_immutable;
1;
