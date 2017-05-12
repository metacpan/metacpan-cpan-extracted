package WWW::BigDoor;

use warnings;
use strict;

use Carp;
use Data::Dumper;
use Digest::SHA qw(sha256_hex);
use JSON;
use REST::Client;
use UUID::Tiny;

#use Smart::Comments -ENV;

use base qw(Class::Accessor);

use version; our $VERSION = qv( '0.1.1' );

BEGIN {
    foreach my $method ( qw(GET POST PUT DELETE) ) {
        no strict 'refs';    ## no critic (ProhibitNoStrict)

        #my $full_method_name = __PACKAGE__.'::'.$method;
        ## full method name: $full_method_name
        *{__PACKAGE__ . '::' . $method} = sub {
            my $response_body = do_request( shift, $method, @_ );

            my $decoded_response_body =
              $response_body && $response_body ne q{}
              ? decode_json( $response_body )
              : undef;       # TODO test for response_body eq q{}
            ## decoded_response_body: $decoded_response_body

            return $decoded_response_body;
          }
    }
}

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
    qw(app_secret app_key api_host base_url request_result response_code response_content) );

sub new {

    my ( $class, $app_secret, $app_key, $api_host ) = @_;

    my $self = {};

    bless( $self, $class );

    ### check: defined $app_secret
    ### check: defined $app_key

    $self->set_app_secret( $app_secret );   # TODO test for empty or undefined app_secret or app_key
    $self->set_app_key( $app_key );
    $self->set_api_host( $api_host || 'http://api.bigdoor.com' );    # TODO test for empty $api_host
    $self->set_base_url( sprintf "/api/publisher/%s", $app_key );

    return $self;
}

sub do_request {
    my ( $self, $method, $endpoint, $params, $payload ) = @_;

    my $rc = REST::Client->new( {host => $self->get_api_host} );

    my $url = $self->get_base_url . '/' . $endpoint;

    ## method: $method
    ## url: $url

    my $par = defined $params  ? {%{$params}}  : undef;
    my $pay = defined $payload ? {%{$payload}} : undef;

    ( $par, $pay ) = $self->_sign_request( $method, $url, $par, $pay );

    ### check: defined $par
    # should be always defined by _sign_request
    my $args = $rc->buildQuery( $par );

    ## args: $args
    ## payload: Dumper($pay)

    my $headers = {
        'User-Agent'   => sprintf( 'BigDoorKit-Perl/%s', $VERSION ),
        'Content-Type' => 'application/x-www-form-urlencoded',
    };

    my $post_body = q{};

    if ( defined $pay ) {
        require URI;
        my $uri_encoded = URI->new( 'http:' );
        $uri_encoded->query_form( $pay );
        $post_body = $uri_encoded->query;

        ## post_body: $post_body
    }

    ### URL: $url . $args
    my $result = $rc->request( $method, $url . $args, $post_body, $headers );

    $self->set_request_result( $result );
    $self->set_response_code( $result->responseCode );
    $self->set_response_content( $result->responseContent );

    ### check: defined $result
    return unless defined $result;

    ### result: Dumper($result->{_res})
    ### response code: $result->responseCode()
    ### check: $result->responseCode < 300
    return if $result->responseCode >= 300;

    ## response content: $result->responseContent()
    ## response headers: Dumper($result->responseHeaders())

    my $response_body = $result->responseContent();
    ### check: defined $response_body
    ### response_body: $response_body

    return $response_body;

} ## end sub do_request

sub _sign_request {
    my ( $self, $method, $url, $params, $payload ) = @_;

    # FIXME use content copy
    my $is_postish = $method =~ /^(POST)|(PUT)$/ix;

    if ( $is_postish && exists $payload->{'time'} ) {
        $params->{'time'} = $payload->{'time'};
    }
    unless ( exists $params->{'time'} ) {
        $params->{'time'} = time;
    }
    if ( $is_postish && !exists $payload->{'time'} ) {
        $payload->{'time'} = $params->{'time'};
    }
    if ( $is_postish && !exists $payload->{'token'} ) {
        $payload->{'token'} = $self->generate_token();
    }
    if ( $method =~ /^DELETE$/ix && !exists $params->{'delete_token'} ) {
        $params->{'delete_token'} = $self->generate_token();
    }

    $params->{'sig'} = $self->generate_signature( $url, $params, $payload );

    ### check: defined $params

    return ( $params, $payload );
} ## end sub _sign_request

sub _flatten_params {
    my ( $params ) = @_;

    my $result = q{};

    foreach my $k ( sort keys %{$params} ) {
        next if $k eq 'sig' || $k eq 'format';
        $result .= sprintf '%s%s', $k, $params->{$k};
    }
    return $result;
}

sub generate_token {
    return unpack( "H*", create_UUID( UUID_V4 ) );
}

sub generate_signature {
    my ( $self, $url, $params, $payload ) = @_;

    my $signature = $url;

    $signature .= _flatten_params( $params )  if defined $params;
    $signature .= _flatten_params( $payload ) if defined $payload;

    $signature .= $self->get_app_secret();

    ### signature: $signature

    return sha256_hex( $signature );
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

WWW::BigDoor - provides a perl interface for BigDoor's REST API.


=head1 VERSION

This document describes BigDoor version 0.1.1


=head1 SYNOPSIS

    use WWW::BigDoor;

    my $client = new WWW::BigDoor( $APP_SECRET, $APP_KEY );

    $currency_type_list = $client->GET( 'currency_type' );
    my $currency_data = {
        pub_title            => 'Banknotes',
        pub_description      => 'an example of the Purchase currency type',
        end_user_title       => 'Coins',
        end_user_description => 'can only be purchased',
        currency_type_id     => $currency_type_list->[0],
        currency_type_title  => 'Purchase',
        exchange_rate        => 900.00,
        relative_weight      => 2,
    };
    my $currency = $client->POST( 'currency', {format => 'json'}, $currency_data );

    my $currency_id = $currency->[0]->{'id'};

    $currency_data->{'pub_title'} = 'Coins';

    $client->PUT( sprintf( 'currency/%s', $currency_id ), {format => 'json'}, $currency_data );

    $currency = $client->GET( sprintf( 'currency/%s', $currency_id ), {format => 'json'} );

    $client->DELETE( sprintf( 'currency/%s', $currency_id ) );

  
=head1 DESCRIPTION

This module provides simple interface to BigDoor REST API with calls
implmenting HTTP methods. For object-oriented interface see WWW::BigDoor::Resource.

For BigDoor API description consult documentation at
L<http://publisher.bigdoor.com/docs/definitions>

=head1 INTERFACE 

=head3  new( $app_secret, $app_key, [$api_host] )

Constructs a new BigDoor API client object. 

=over 4

=item app_secret

The API secret supplied by BigDoor. (see API Keys L<http://publisher.bigdoor.com/>)

=item app_key

The API key supplied by BigDoor. (see API Keys L<http://publisher.bigdoor.com/>)

=item api_host

An alternative host to enable use with testing servers.

=back

=head3 GET( $end_point, $params )

Sends a GET request to the API and returns a hash/array reference as returned
from decode_json from JSON module.

=over 4

=item end_point

The relative URI that comes directly after your API key in the BigDoor
documentation.

=item params

The parameters to be sent via the GET query string.

=back

=head3 PUT( $end_point, $params, $payload )

Sends a PUT request to the API and returns a hash/array reference as returned
from decode_json from JSON module.

=over 4

=item end_point

The relative URI that comes directly after your API key in the BigDoor
documentation.

=item params

The parameters to be sent via the PUT query string.

=item payload

The parameters to be sent via the PUT request body.

=back

=head3 POST( $end_point, $params, $payload )

Sends a POST request to the API and returns a hash/array reference as returned
from decode_json from JSON module.

=over 4

=item end_point

The relative URI that comes directly after your API key in the BigDoor
documentation.

=item params

The parameters to be sent via the PUT query string.

=item payload

The parameters to be sent via the PUT request body.

=back

=head3 DELETE( $end_point, $params )

Sends a DELETE request to the API and returns nothing.

=head3 do_request( $method, $end_point, $params, $payload )

Sends a request to the API, signing it before it is sent.  Returns ?

=over 4

=item method

HTTP method of request, can be one of GET, PUT, POST, DELETE.

=item end_point

The relative URI that comes directly after your API key in the BigDoor
documentation.

=item params

The parameters to be sent via the query string.

=item payload

The parameters to be sent via the PUT or POST request body.

=back

=head3 generate_signature( $url, $params, $payload )

Generates the appropriate signature given a url and optional params.

=over 4

=item url

The full URL, including the base /api/publisher/[app_key].

=item params

The parameters to be sent via the query string.

=item payload

The parameters to be sent via the PUT or POST request body.

=back

=head3 generate_token()

Generate UUID4 token

=head2 Accessors/Mutators generated with Class::Accessor


=head3 [get|set]_app_secret()

Get/Set secret for BigDoor API.

=head3 [get|set]_app_key()

Get/Set secret for BigDoor API.

=head3 [get|set]_api_host()

Get/Set hostname for server providing BigDoor API.

=head3 [get|set]_base_url()

Get/Set base URL for API (default is C</api/published/[$app_key]>)

=head3 get_request_result()

Gets request result returned by underlying C<REST::Client> C<request()> call

=head3 get_response_code()

Gets HTTP response code for request.

=head3 get_response_content()

Gets undecoded response body content.

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

Module doesn't produce any error or warning messages on its own. 

In case of HTTP errors check HTTP response code returned by
C<get_response_code()> or response body returned by C<get_response_content()>.

For debugging purpose there is result object returned by REST::Client
c<request()> call which could be accessed through C<get_request()> and this
result object contains HTTP::Response object.

=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
WWW::BigDoor requires no configuration files or environment variables.

=head1 DEPENDENCIES

The module requires the following modules:

=over

=item *

REST::Client

=item *

JSON

=item *

URI

=item *

Digest::SHA

=item *

UUID::Tiny

=back

Test suite requires additional modules:

=over

=item *

Test::Most

=item *

Test::MockObject

=item *

Test::MockModule

=item *

Test::NoWarnings

=item *

Hook::LexWrap

=back

=head1 DIFFERENCES FROM PYTHON BIGDOORKIT

Method names get/put/post/delete were converted to upper case to avoid conflict
with C<get()> method inherited from Class::Accessor and for consinstence with
LWP.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Code is not fully covered by tests and there are not much tests for failures
and, as consequence, not much parameters validation or checking for error
conditions. Don't expect too much diagnosticts in case of errors.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-bigdoor@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

=over

=item * 

Implement parameters checking

=item * 

Improve test coverage

=back

=head1 SEE ALSO

WWW::BigDoor::Resource for object-oriented interface.

=head1 AUTHOR

Alex L. Demidov  C<< <alexeydemidov@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

BigDoor Open License
Copyright (c) 2010 BigDoor Media, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to
do so, subject to the following conditions:

- This copyright notice and all listed conditions and disclaimers shall
be included in all copies and portions of the Software including any
redistributions in binary form.

- The Software connects with the BigDoor API (api.bigdoor.com) and
all uses, copies, modifications, derivative works, mergers, publications,
distributions, sublicenses and sales shall also connect to the BigDoor API and
shall not be used to connect with any API, software or service that competes
with BigDoor's API, software and services.

- Except as contained in this notice, this license does not grant you rights to
use BigDoor Media, Inc. or any contributors' name, logo, or trademarks.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
