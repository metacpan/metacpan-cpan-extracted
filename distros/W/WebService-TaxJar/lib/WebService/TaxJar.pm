use strict;
use warnings;
package WebService::TaxJar;
$WebService::TaxJar::VERSION = '0.0001';
use HTTP::Thin;
use HTTP::Request::Common qw/GET DELETE PUT POST/;
use HTTP::CookieJar;
use JSON;
use URI;
use Ouch;
use Moo;

=head1 NAME

WebService::TaxJar - A simple client to L<TaxJar's REST API|https://www.taxjar.com/api/>.

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

 use WebService::TaxJar;

 my $tj = WebService::TaxJar->new(api_key => 'XXXXXXXXXXxxxxxxxxxxxx', version => 'v2');

 my $categories = $tj->get('categories');

=head1 DESCRIPTION

A light-weight wrapper for TaxJar's RESTful API (an example of which can be found at: L<https://www.thegamecrafter.com/developer/>). This wrapper basically hides the request cycle from you so that you can get down to the business of using the API. It doesn't attempt to manage the data structures or objects the web service interfaces with.

The module takes care of all of these things for you:

=over 4

=item Host selection

Based on the value of the C<sandbox> flag, the module will either send requests to the production environment C<sandbox =E<gt> 0> or the sandbox environment C<sandbox =E<gt> 1>.

=item Adding authentication headers

C<WebService::TaxJar> adds an authentication header of the type "Authorization: Bearer C<$tj-E<gt>api_key>" to each request.

=item Adding api version number to URLs

C<WebService::TaxJar> prepends the C< $tj-E<gt>version > to each URL you submit.

=item PUT/POST data translated to JSON

When making a request like:

    $tj->post('customers', { customer_id => '27', exemption_type => 'non_exempt', name => 'Andy Dufresne', });

The data in POST request will be translated to JSON using <JSON::to_json>.

=item Response data is deserialized from JSON and returned from each call.

=back

=head1 EXCEPTIONS

All exceptions in C<WebService::TaxJar> are handled by C<Ouch>.  A 500 exception C<"Server returned unparsable content."> is returned if TaxJar's server returns something that isn't JSON.  If the request isn't successful, then an exception with the code and response and string will be thrown.

=head1 METHODS

The following methods are available.

=head2 new ( params ) 

Constructor.

=over

=item params

A hash of parameters.

=over

=item api_key

Your key for accessing TaxJar's API.  Required.

=item version

The version of the API that you are using, like 'v1', 'v2', etc.  Required.

=item sandbox

A boolean that, if true, will send all requests to TaxJar's sandbox environment for testing instead of to production.  Defaults to 0.

=cut

=item debug_flag

Just a spare, writable flag so that users of the object should log debug information, since TaxJar will likely ask for request/response pairs when
you're having problems.

    my $sales_tax = $taxjar->get('taxes', $order_information);
    if ($taxjar->debug_flag) {
        $log->info($taxjar->last_response->request->as_string);
        $log->info($taxjar->last_response->content);
    }

=cut

has api_key => (
    is          => 'ro',
    required    => 1,
);

has version => (
    is          => 'ro',
    required    => 1,
);

has sandbox => (
    is          => 'ro',
    required    => 0,
    default     => sub { 0 },
);

has debug_flag => (
    is          => 'rw',
    required    => 0,
    default     => sub { 0 },
);

=item agent

A LWP::UserAgent compliant object used to keep a persistent cookie_jar across requests.  By default this module uses HTTP::Thin, but you can supply another object when
creating a WebService::TaxJar object.

=back

=back

=cut

has agent => (
    is          => 'ro',
    required    => 0,
    lazy        => 1,
    builder     => '_build_agent',
);

sub _build_agent {
    return HTTP::Thin->new( cookie_jar => HTTP::CookieJar->new() )
}

=head2 last_response

The HTTP::Response object from the last request/reponse pair that was sent, for debugging purposes.

=cut

has last_response => (
    is       => 'rw',
    required => 0,
);

=head2 get(path, params)

Performs a C<GET> request, which is used for reading data from the service.

=over

=item path

The path to the REST interface you wish to call. 

=item params

A hash reference of parameters you wish to pass to the web service.  These parameters will be added as query parameters to the URL for you.

=back

=cut

sub get {
    my ($self, $path, $params) = @_;
    my $uri = $self->_create_uri($path);
    $uri->query_form($params);
    return $self->_process_request( GET $uri->as_string );
}

=head2 delete(path)

Performs a C<DELETE> request, deleting data from the service.

=over

=item path

The path to the REST interface you wish to call.

=item params

A hash reference of parameters you wish to pass to the web service.  These parameters will be added as query parameters to the URL for you.

=back

=cut

sub delete {
    my ($self, $path, $params) = @_;
    my $uri = $self->_create_uri($path);
    $uri->query_form($params);
    return $self->_process_request( DELETE $uri->as_string );
}

=head2 put(path, json)

Performs a C<PUT> request, which is used for updating data in the service.

=over

=item path

The path to the REST interface you wish to call.

=item params

A hash reference of parameters you wish to pass to Tax Jar.  This will be translated to JSON.

=back

=cut

sub put {
    my ($self, $path, $params) = @_;
    my $uri = $self->_create_uri($path);
    my %headers = ( Content => to_json($params), "Content-Type" => 'application/json', );
    return $self->_process_request( POST $uri->as_string,  %headers );
}

=head2 post(path, params, options)

Performs a C<POST> request, which is used for creating data in the service.

=over

=item path

The path to the REST interface you wish to call.

=item params

A hash reference of parameters you wish to pass to Tax Jar.  They will be encoded as JSON.

=back

=head2 Notes

The path you provide as arguments to the request methods C<get, post, put delete> should not have a leading slash.

As of early 2019:

The current version of their API is 'v2'.  There is no default value for the C<version> parameter, so please provide this when creating a WebService::TaxJar object.

TaxJar does not provide a free sandbox for prototyping your code, it is part of their premium service level.

TaxJar's sandbox mode does not implement all API endpoints.

=cut

sub post {
    my ($self, $path, $params) = @_;
    my $uri = $self->_create_uri($path);
    my %headers = ( Content => to_json($params), "Content-Type" => 'application/json', );
    return $self->_process_request( POST $uri->as_string, %headers );
}

sub _create_uri {
    my $self = shift;
    my $path = shift;
    my $host = $self->sandbox
             ? 'https://api.sandbox.taxjar.com'
             : 'https://api.taxjar.com'
             ;
    return URI->new(join '/', $host, $self->version, $path);
}

sub _add_auth_header {
    my $self    = shift;
    my $request = shift;
    $request->header( Authorization => 'Bearer '.$self->api_key() );
    return;
}

sub _process_request {
    my $self = shift;
    my $request = shift;
    $self->_add_auth_header($request);
    my $response = $self->agent->request($request);
    $response->request($request);
    $self->last_response($response);
    $self->_process_response($response);
}

sub _process_response {
    my $self = shift;
    my $response = shift;
    my $result = eval { from_json($response->decoded_content) }; 
    if ($@) {
        ouch 500, 'Server returned unparsable content.', { error => $@, content => $response->decoded_content };
    }
    elsif ($response->is_success) {
        return from_json($response->content);
    }
    else {
        ouch $response->code, $response->as_string;
    }
}

=head1 PREREQS

L<HTTP::Thin>
L<Ouch>
L<HTTP::Request::Common>
L<HTTP::CookieJar>
L<JSON>
L<URI>
L<Moo>

=head1 SUPPORT

=over

=item Repository

L<https://github.com/perldreamer/WebService-TaxJar>

=item Bug Reports

L<https://github.com/perldreamer/WebService-TaxJar/issues>

=back

=head1 AUTHOR

Colin Kuskie <colink_at_plainblack_dot_com>

=head1 LEGAL

This module is Copyright 2019 Plain Black Corporation. It is distributed under the same terms as Perl itself. 

=cut

1;
