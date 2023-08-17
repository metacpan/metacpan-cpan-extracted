package WebService::Async::SmartyStreets;

# ABSTRACT: Access SmartyStreet API

use strict;
use warnings;

our $VERSION = '0.002';

=head1 NAME

WebService::Async::SmartyStreets - calls the SmartyStreets API and checks for the validity of the address

=head1 SYNOPSIS

    my $ss = WebService::Async::SmartyStreets->new(
        # Obtain these from your SmartyStreets account page.
        # These will be used for US lookups
        us_auth_id => '...',
        us_token   => '...',
        # For non-US address lookups, you would also need an international token
        international_auth_id => '...',
        international_token   => '...',
    );
    IO::Async::Loop->new->add($ss);

    print $ss->verify(
        city => 'Atlanta',
        country => 'US',
        geocode => 1
    )->get->status;

=head1 DESCRIPTION

This module provides basic support for the L<SmartyStreets API|https://smartystreets.com/>.

Note that this module uses L<Future::AsyncAwait>.

=cut

use parent qw(IO::Async::Notifier);

use mro;
no indirect;

use URI;
use URI::QueryParam;

use Future::AsyncAwait;
use Net::Async::HTTP;
use JSON::MaybeUTF8 qw(:v1);
use Syntax::Keyword::Try;
use Scalar::Util qw(blessed);

use WebService::Async::SmartyStreets::Address;

use Log::Any qw($log);

=head2 verify

Makes connection to SmartyStreets API and parses the response into WebService::Async::SmartyStreets::Address.

    my $addr = $ss->verify(%address_to_check)->get;

Takes the following named parameters:

=over 4

=item * C<country> - country (required)

=item * C<address1> - address line 1

=item * C<address2> - address line 2

=item * C<organization> - name of organization (usually building names)

=item * C<locality> - city

=item * C<administrative_area> - state

=item * C<postal_code> - post code

=item * C<geocode> - true or false

=back

Returns a L<Future> which should resolve to a valid L<WebService::Async::SmartyStreets::Address> instance.

=cut

# keyword 'async' will cause critic test fail. disable it
## no critic (RequireEndWithOne.pm)
async sub verify {
    my ($self, %args) = @_;

    my $uri = $self->country_endpoint($args{country})->clone;

    $uri->query_param($_ => $args{$_}) for keys %args;
    $uri->query_param(
        'auth-id' => ($self->auth_id($args{country}) // die 'need an auth ID'),
    );
    $uri->query_param(
        'auth-token' => ($self->token($args{country}) // die 'need an auth token'),
    );
    $uri->query_param(
        'input-id' => $self->next_id,
    );
    $log->tracef('GET %s', '' . $uri);

    my $decoded = await get_decoded_data($self, $uri);

    $log->tracef('=> %s', $decoded);
    $decoded = [$decoded] unless ref($decoded) eq 'ARRAY';

    return map { WebService::Async::SmartyStreets::Address->new(%$_) } @$decoded;
}

=head2 METHODS - Accessors

=cut

sub country_endpoint {
    my ($self, $country) = @_;
    return $self->us_endpoint if uc($country) eq 'US';
    return $self->international_endpoint;
}

sub us_endpoint {
    shift->{us_endpoint} //= URI->new('https://us-street.api.smartystreets.com/street-address');
}

sub international_endpoint {
    shift->{international_endpoint} //= URI->new('https://international-street.api.smartystreets.com/verify');
}

sub auth_id {
    my ($self, $country) = @_;
    return $self->{us_auth_id} if uc($country) eq 'US';
    return $self->{international_auth_id};
}

sub token {
    my ($self, $country) = @_;
    return $self->{us_token} if uc($country) eq 'US';
    return $self->{international_token};
}

=head1 METHODS - Internal

=head2 get_decoded_data

Calls the SmartyStreets API then decode and parses the response give by SmartyStreets

    my $decoded = await get_decoded_data($self, $uri)

Takes the following parameters:

=over 4

=item * C<$uri> - URI for endpoint

=back

More information on the response can be seen in L<SmartyStreets Documentation | https://smartystreets.com/docs/cloud/international-street-api>.

Returns a L<Future> which resolves to an arrayref of L<WebService::Async::SmartyStreets::Address> instances.

=cut

async sub get_decoded_data {
    my $self = shift;
    my $uri  = shift;

    my $res;
    try {
        $res = await $self->ua->GET($uri);
    } catch ($e) {
        if (blessed($e) and $e->isa('Future::Exception')) {
            my ($payload) = $e->details;

            if (blessed($payload) && $payload->can('content')) {
                if (my $resp = eval { decode_json_utf8($payload->content) }) {
                    my $errors = $resp->{errors} // [];
                    my ($error) = $errors->@*;

                    if ($error && $error->{message}) {

                        # structured response may be useful for further processing
                        die $e;
                    }
                }
            }
        }

        # throw a generic error
        die 'Unable to retrieve response.';
    };

    my $response = decode_json_utf8($res->decoded_content);

    return $response->[0];
}

=head2 configure

Configures the instance.

Takes the following named parameters:

=over 4

=item * C<international_auth_id> - auth_id obtained from SmartyStreet

=item * C<international_token> - token obtained from SmartyStreet

=item * C<us_auth_id> - auth_id obtained from SmartyStreet

=item * C<us_token> - token obtained from SmartyStreet

=back

Note that you can provide US, international or both API tokens - if an API token
is not available for a L</verify> call, then it will return a failed L<Future>.

=cut

sub configure {
    my ($self, %args) = @_;
    for my $k (qw(international_auth_id international_token us_auth_id us_token)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    $self->next::method(%args);
}

sub next_id {
    ++(shift->{id} //= 'AA00000000');
}

=head2 ua

Accessor for the L<Net::Async::HTTP> instance which will be used for SmartyStreets API requests.

=cut

sub ua {
    my ($self) = @_;
    $self->{ua} //= do {
        $self->add_child(
            my $ua = Net::Async::HTTP->new(
                fail_on_error            => 1,
                decode_content           => 1,
                pipeline                 => 0,
                max_connections_per_host => 4,
                user_agent               =>
                    'Mozilla/4.0 (WebService::Async::SmartyStreets; BINARY@cpan.org; https://metacpan.org/pod/WebService::Async::SmartyStreets)',
            ));
        $ua;
    }
}

1;

