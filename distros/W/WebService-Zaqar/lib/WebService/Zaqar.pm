package WebService::Zaqar;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;
use HTTP::Request;
use JSON;
use Net::HTTP::Spore;
use List::Util qw/first/;
use Scalar::Util qw/blessed weaken/;
use Data::UUID;
use Try::Tiny;
use File::ShareDir;

our $VERSION = '0.010';

has 'base_url' => (is => 'ro',
                   writer => '_set_base_url');
has 'token' => (is => 'ro',
                writer => '_set_token',
                clearer => '_clear_token',
                predicate => 'has_token');
has 'spore_client' => (is => 'ro',
                       lazy => 1,
                       builder => '_build_spore_client');
has 'spore_description_file' => (is => 'ro',
                                 default => sub { File::ShareDir::dist_file('WebService-Zaqar', 'marconi.spore.json') });
has 'client_uuid' => (is => 'ro',
                      lazy => 1,
                      builder => '_build_uuid');

has 'wants_auth' => (is => 'ro',
                     default => sub { 0 });
has 'rackspace_keystone_endpoint' => (is => 'ro',
                                      predicate => 1);
has 'rackspace_username' => (is => 'ro',
                             predicate => 1);
has 'rackspace_api_key' => (is => 'ro',
                            predicate => 1);

sub _build_uuid {
    return Data::UUID->new->create_str;
}

sub _build_spore_client {
    my $self = shift;
    my $client = Net::HTTP::Spore->new_from_spec($self->spore_description_file,
                                                 base_url => $self->base_url);
    # all payloads serialized/deserialized to/from JSON -- except if
    # you're receiving 401 or 403
    $client->enable('+WebService::Zaqar::Middleware::Format::JSONSometimes');
    # set X-Auth-Token header to the Cloud Identity token, if
    # available (local instances don't use that, for instance)

    my $twin = $self; # gonna close over this one
    weaken $twin;

    $client->enable('+WebService::Zaqar::Middleware::Auth::DynamicHeader',
                    header_name => 'X-Auth-Token',
                    header_value_callback => sub {
                        # HTTP::Headers says, if the value of the
                        # header is undef, the field is removed
                        return $twin ? $twin->has_token ? $twin->token : undef : undef
                    });
    # all requests should contain a Date header with an RFC 1123 date
    $client->enable('+WebService::Zaqar::Middleware::DateHeader');
    # each client using the queue should provide an UUID; the docs
    # recommend that for a given client it should persist between
    # restarts
    $client->enable('Header',
                    header_name => 'Client-ID',
                    header_value => $self->client_uuid);
    $client->enable('+WebService::Zaqar::Middleware::JustCallIt');
    return $client;
}

sub do_request {
    my ($self, $coderef, $options, @rest) = @_;
    # here undef retries means retry until it works, 0 retries means
    # don't retry, other integers mean retry that many times
    my $max_retries = $options->{retries};
    my $current_retries = 0;
    RETRY: {
        my $return_value;
        try {
            $return_value = $coderef->($self, @rest);
        } catch {
            my $exception = $_;
            if (blessed($exception)
                and $exception->isa('Net::HTTP::Spore::Response')) {
                if ($exception->code == 401) {
                    if (defined $max_retries and $current_retries >= $max_retries) {
                        croak('Server returned 401 Unauthorized but we already retried too many times');
                    }
                    $current_retries++;
                    # re-authentication needed
                    if ($self->wants_auth) {
                        $self->rackspace_authenticate(
                            $self->rackspace_keystone_endpoint,
                            $self->rackspace_username,
                            $self->rackspace_api_key);
                       goto RETRY;
                    } else {
                        # ... but not wanted!
                        croak('Server returned 401 Unauthorized but we are not planning on authenticating!');
                    }
                }
                # rethrow the contents of the exception instead of just
                # the unhelpful HTTP 400
                if ($exception->code == 599) {
                    croak($exception->body->{error});
                }
                # some other SPORE exception
                croak $exception;
            }
            # wasn't a Spore exception, rethrow
            croak $exception;
        };
        return $return_value;
    }
}

sub rackspace_authenticate {
    my ($self, $cloud_identity_uri, $username, $apikey) = @_;
    my $request = HTTP::Request->new('POST', $cloud_identity_uri,
                                     [ 'Content-Type' => 'application/json' ],
                                     JSON::encode_json({
                                         auth => {
                                             'RAX-KSKEY:apiKeyCredentials' => {
                                                 username => $username,
                                                 apiKey => $apikey } } }));
    my $response = $self->spore_client->api_useragent->request($request);
    my $content = $response->decoded_content;
    my $structure = JSON::decode_json($content);
    my $token = $structure->{access}->{token}->{id};
    $self->_set_token($token);
    # the doc says we should read the catalog to determine the
    # endpoint...
    # my $catalog = first { $_->{name} eq 'cloudQueues'
    #                           and $_->{type} eq 'rax:queues' } @{$structure->{serviceCatalog}};
    return $token;
}

sub BUILD {
    my $self = shift;
    if ($self->wants_auth
        and (not $self->has_rackspace_keystone_endpoint
             or not $self->has_rackspace_username
             or not $self->has_rackspace_api_key)) {
        croak('Authentication required but not all Rackspace attributes provided');
    }
    # if ($self->has_rackspace_username) {
    #     # uhhh, ok, so SOME Rackspace docs say this header is
    #     # necessary, but others don't mention it; when I add it to a
    #     # request it always 403s and without it it seems to work, so
    #     # uh, yeah.
    #     $self->spore_client->enable('Header',
    #                                 header_name => 'X-Project-Id',
    #                                 header_value => '921182');
    # }
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $method_name = $AUTOLOAD;
    my ($self, @rest) = @_;
    my $current_class = ref $self;
    $method_name =~ s/^${current_class}:://;
    $self->spore_client->$method_name(@rest);
}

1;
__END__
=pod

=head1 NAME

WebService::Zaqar -- Wrapper around the Zaqar (aka Marconi) message queue API

=head1 SYNOPSIS

  use WebService::Zaqar;
  my $client = WebService::Zaqar->new(
      # base_url => 'https://dfw.queues.api.rackspacecloud.com/',
      base_url => 'http://localhost:8888',
      spore_description_file => 'share/marconi.spore.json');
  
  # for Rackspace only
  my $token = $client->rackspace_authenticate('https://identity.api.rackspacecloud.com/v2.0/tokens',
                                              $rackspace_account,
                                              $rackspace_key);
  
  $client->create_queue(queue_name => 'pets');
  $client->post_messages(queue_name => 'pets',
                         payload => [
                             { ttl => 120,
                               body => [ 'pony', 'horse', 'warhorse' ] },
                             { ttl => 120,
                               body => [ 'little dog', 'dog', 'large dog' ] } ]);
  $client->post_messages(queue_name => 'pets',
                         payload => [
                             { ttl => 120,
                               body => [ 'aleax', 'archon', 'ki-rin' ] } ]);

=head1 DESCRIPTION

This library is a L<Net::HTTP::Spore>-based client for the message
queue component of OpenStack,
L<Zaqar|https://wiki.openstack.org/wiki/Marconi/specs/api/v1>
(previously known as "Marconi").

On top of allowing you to make requests to a Zaqar endpoint, this
library also supports Rackspace authentication using their L<Cloud
Identity|http://docs.rackspace.com/queues/api/v1.0/cq-gettingstarted/content/Generating_Auth_Token.html>
token system; see C<do_request>.

=head1 ATTRIBUTES

=head2 base_url

(read-only string)

The base URL for all API queries, except for the Rackspace-specific
authentication.

=head2 client_uuid

(read-only string, defaults to a new UUID)

All API queries B<should> contain a "Client-ID" header (in practice,
some appear to work without this header).  If you do not provide a
value, a new one will be built with L<Data::UUID>.

The docs recommend reusing the same client UUID between restarts of
the client.

=head2 rackspace_api_key

(read-only optional string)

API key for Rackspace authentication endpoints.

=head2 rackspace_keystone_endpoint

(read-only optional string)

URL for Rackspace authentication endpoints.

=head2 rackspace_username

(read-only optional string)

Your Rackspace API username.

=head2 spore_client

(read-only object)

This is the L<Net::HTTP::Spore> client build with the
C<spore_description_file> attribute.  All API method calls will be
delegated to this object.

=head2 spore_description_file

(read-only required file path or URL)

Path to the SPORE specification file or remote resource.

A spec file for Zaqar v1.0 is provided in the distribution (see
F<share/marconi.spec.json>).

=head2 token

(read-only string with default predicate)

The token is automatically set when calling C<rackspace_authenticate>
successfully.  Once set, it will be sent in the "X-Auth-Token" header
with each query.

Rackspace invalidates the token after 24h, at which point all the
queries will start returning "401 Unauthorized".  Consider using
C<do_request> to manage this for you.

=head2 wants_auth

(read-only boolean, defaults to false)

If this attribute is set to true, you are indicating that the endpoint
needs authentication.  This means that when a request wrapped with
C<do_request> fails with "401 Unauthorized", the client will try
(re-)authenticating with C<rackspace_authenticate>, using the values
in C<rackspace_keystone_endpoint>, C<rackspace_username> and
C<rackspace_api_key>.

=head1 METHODS

=head2 DELEGATED METHODS

All methods listed in L<the API
docs|https://wiki.openstack.org/wiki/Marconi/specs/api/v1> are
implemented by the SPORE client.  When a body is required, you must
provide it via the C<payload> parameter.

See the F<share/marconi.spore.json> file for the list of methods and
their parameters.

All those methods can be called with an instance of
L<WebService::Zaqar> as invocant; they will be delegated to the SPORE
client.

Unlike "regular" SPORE-based clients, you may use the special
C<__url__> parameter to provide an already-built URL directly.  This
is helpful when trying to follow links provided by the API itself.
E.g. when you make a claim on a queue, the server does not return the
claim and message IDs; instead it returns URLs to the claim and
messages, which you are then supposed to call if you want to release
or update the claim, delete a message, etc.

  my $response = $client->claim_messages(queue_name => 'potato');
  my $claim_href = $response->header('Location');
  $client->release_claim(__url__ => $claim_href);

=head2 do_request

  my $response = $client->do_request(sub { $client->list_queues(limit => 20) },
                                     { retries => 2 },
                                     @etc);

This method can be used to manage token generation.  The first
argument should be a coderef; it will be executing within a C<try { }>
statement.  If the coderef throws a blessed exception of class
L<Net::HTTP::Spore::Response> (or a subclass thereof), that response's
status is "401 Unauthorized", and C<wants_auth> was set to a true
value, C<rackspace_authenticate> will be called and the coderef will
be retried.

If the exception has another status code, it will be rethrown as-is,
without retrying.  This generally leads to a somewhat cryptic "HTTP
response: 403" exception, since L<Net::HTTP::Spore::Response> objects
stringify to their status code.  If the status code was 599 (internal
exception), the response's error message will be thrown instead.

If the exception is not a L<Net::HTTP::Spore::Response> instance at
all, it will be rethrown directly.

Otherwise, the coderef's return value is returned.

The second argument is a hashref of options.  Currently only "retries"
is implemented:

=over 4

=item if "retries" is undefined or not provided, C<do_request> will
retry indefinitely until successful

=item if "retries" is 0, C<do_request> will not retry

=item if "retries" is any other integer, C<do_request> will retry up
to that many times.

=back

The coderef will be called with the original invocant of C<do_request>
and the rest of the arguments of C<do_request> as parameters.

=head2 rackspace_authenticate

  my $token = $client->rackspace_authenticate('https://identity.api.rackspacecloud.com/v2.0/tokens',
                                              $rackspace_account,
                                              $rackspace_key);

Sends an HTTP request to a L<Cloud
Identity|http://docs.rackspace.com/queues/api/v1.0/cq-gettingstarted/content/Generating_Auth_Token.html>
endpoint (or compatible) and sets the token received.

See also L</token>.

=head1 SPORE MIDDLEWARES ENABLED

The following modifications are applied to requests before they are
made, in order:

=over 4

=item serializing the body to JSON

=item setting the C<X-Auth-Token> header to the authentication token,
if available

=item setting the C<Date> header to the current date in RFC 1123
format

=item setting the C<Client-ID> header to the value of the
C<client_uuid> attribute

=item if the C<__url__> parameter is provided to the method call,
replace the request path and querystring params with its value

=back

The following modifications are applied to responses before they are
returned, in order:

=over 4

=item deserializing the body from JSON, except for 401 and 403
responses, which are likely to come from Keystone instead and are
plain text.

=back

=head1 SEE ALSO

L<Net::HTTP::Spore>

=head1 AUTHOR

Fabrice Gabolde <fgabolde@weborama.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Weborama

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301, USA.

=cut
