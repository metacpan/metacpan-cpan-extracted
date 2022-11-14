package WebService::Async::CustomerIO;

use strict;
use warnings;

our $VERSION = '0.001';

=head1 NAME

WebService::Async::CustomerIO - unofficial support for the Customer.io service

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use parent qw(IO::Async::Notifier);

use mro;
use Syntax::Keyword::Try;
use Future;
use Net::Async::HTTP;
use Carp            qw();
use JSON::MaybeUTF8 qw(:v1);
use URI::Escape;

use WebService::Async::CustomerIO::Customer;
use WebService::Async::CustomerIO::RateLimiter;
use WebService::Async::CustomerIO::Trigger;

use constant {
    TRACKING_END_POINT => 'https://track.customer.io/api/v1',
    API_END_POINT      => 'https://api.customer.io/v1',
    RATE_LIMITS        => {
        track => {
            limit    => 30,
            interval => 1
        },
        api => {
            limit    => 10,
            interval => 1
        },
        trigger => {
            limit    => 1,
            interval => 10
        },    # https://www.customer.io/docs/api/#operation/triggerBroadcast
    }};

=head2 new

Creates a new API client object

Usage: C<< new(%params) -> obj >>

Parameters:

=over 4

=item * C<site_id>

=item * C<api_key>

=item * C<api_token>

=back

=cut

sub _init {
    my ($self, $args) = @_;

    for my $k (qw(site_id api_key api_token)) {
        Carp::croak "Missing required argument: $k" unless exists $args->{$k};
        $self->{$k} = delete $args->{$k} if exists $args->{$k};
    }

    return $self->next::method($args);
}

sub configure {
    my ($self, %args) = @_;

    for my $k (qw(site_id api_key api_token)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }

    return $self->next::method(%args);
}

=head2 site_id

=cut

sub site_id { return shift->{site_id} }

=head2 api_key

=cut

sub api_key { return shift->{api_key} }

=head2 api_token

=cut

sub api_token { return shift->{api_token} }

=head2 API endpoints:

There is 2 stable API for Customer.io, if you need to add a new method check
the L<documentation for API|https://customer.io/docs/api/> which endpoint
you need to use:

=over 4

=item * C<Tracking API> - Behavioral Tracking API is used to identify and track
customer data with Customer.io.

=item * C<Regular API> - Currently, this endpoint is used to fetch list of customers
given an email and for sending
L<API triggered broadcasts|https://customer.io/docs/api-triggered-broadcast-setup>.

=back

=head2 tracking_request

Sending request to Tracking API end point.

Usage: C<< tracking_request($method, $uri, $data) -> future($data) >>

=cut

sub tracking_request {
    my ($self, $method, $uri, $data) = @_;
    return $self->ratelimiter('track')->acquire->then(
        sub {
            $self->_request($method, join(q{/} => (TRACKING_END_POINT, $uri)), $data);
        });
}

=head2 api_request

Sending request to Regular API end point with optional limit type.

Usage: C<< api_request($method, $uri, $data, $limit_type) -> future($data) >>

=cut

sub api_request {
    my ($self, $method, $uri, $data, $limit_type) = @_;

    Carp::croak('API token is missed') unless $self->api_token;

    return $self->ratelimiter($limit_type // 'api')->acquire->then(
        sub {
            $self->_request($method, join(q{/} => (API_END_POINT, $uri)), $data, {authorization => 'Bearer ' . $self->api_token},);
        });
}

sub ratelimiter {
    my ($self, $type) = @_;

    return $self->{ratelimiters}{$type} if $self->{ratelimiters}{$type};

    Carp::croak "Can't use rate limiter without a loop" unless $self->loop;

    $self->{ratelimiters}{$type} = WebService::Async::CustomerIO::RateLimiter->new(RATE_LIMITS->{$type}->%*);

    $self->add_child($self->{ratelimiters}{$type});

    return $self->{ratelimiters}{$type};
}

my %PATTERN_FOR_ERROR = (
    RESOURCE_NOT_FOUND  => qr/^404$/,
    INVALID_REQUEST     => qr/^400$/,
    INVALID_API_KEY     => qr/^401$/,
    INTERNAL_SERVER_ERR => qr/^50[0234]$/,
);

sub _request {
    my ($self, $method, $uri, $data, $headers) = @_;

    my $body =
          $data             ? encode_json_utf8($data)
        : $method eq 'POST' ? q{}
        :                     undef;

    return $self->_ua->do_request(
        method => $method,
        uri    => $uri,
        $headers->{authorization} ? ()
        : (
            user => $self->site_id,
            pass => $self->api_key,
        ),
        !defined $body ? ()
        : (
            content      => $body,
            content_type => 'application/json',
        ),
        headers => $headers // {},

    )->catch(
        sub {
            my ($code_msg, $err_type, $response) = @_;

            return Future->fail(@_) unless $err_type && $err_type eq 'http';

            my $code         = $response->code;
            my $request_data = {
                method => $method,
                uri    => $uri,
                data   => $data
            };

            for my $error_code (keys %PATTERN_FOR_ERROR) {
                next unless $code =~ /$PATTERN_FOR_ERROR{$error_code}/;
                return Future->fail($error_code, 'customerio', $request_data);
            }

            return Future->fail('UNEXPECTED_HTTP_CODE: ' . $code_msg, 'customerio', $response);
        }
    )->then(
        sub {
            my ($response) = @_;
            try {
                my $response_data = decode_json_utf8($response->content);
                return Future->done($response_data);
            } catch {
                return Future->fail('UNEXPECTED_RESPONSE_FORMAT', 'customerio', $@, $response);
            }
        });
}

sub _ua {
    my ($self) = @_;

    return $self->{ua} if $self->{ua};

    $self->{ua} = Net::Async::HTTP->new(
        fail_on_error            => 1,
        decode_content           => 0,
        pipeline                 => 0,
        stall_timeout            => 60,
        max_connections_per_host => 4,
        user_agent => 'Mozilla/4.0 (WebService::Async::CustomerIO; BINARY@cpan.org; https://metacpan.org/pod/WebService::Async::CustomerIO)',
    );

    $self->add_child($self->{ua});

    return $self->{ua};
}

=head2 new_customer

Creating new customer object

Usage: C<< new_customer(%params) -> obj >>

=cut

sub new_customer {
    my ($self, %param) = @_;

    return WebService::Async::CustomerIO::Customer->new(%param, api_client => $self);
}

=head2 new_trigger

Creating new trigger object

Usage: C<< new_trigger(%params) -> obj >>

=cut

sub new_trigger {
    my ($self, %param) = @_;

    return WebService::Async::CustomerIO::Trigger->new(%param, api_client => $self);
}

=head2 new_customer

Creating new customer object

Usage: C<< new_customer(%params) -> obj >>

=cut

sub emit_event {
    my ($self, %params) = @_;

    return $self->tracking_request(
        POST => 'events',
        \%params
    );
}

=head2 add_to_segment

Add people to a manual segment.

Usage: C<< add_to_segment($segment_id, @$customer_ids) -> Future() >>

=cut

sub add_to_segment {
    my ($self, $segment_id, $customers_ids) = @_;

    Carp::croak 'Missing required attribute: segment_id' unless $segment_id;
    Carp::croak 'Invalid value for customers_ids'        unless ref $customers_ids eq 'ARRAY';

    return $self->tracking_request(
        POST => "segments/$segment_id/add_customers",
        {ids => $customers_ids});
}

=head2 remove_from_segment

remove people from a manual segment.

usage: c<< remove_from_segment($segment_id, @$customer_ids) -> future() >>

=cut

sub remove_from_segment {
    my ($self, $segment_id, $customers_ids) = @_;

    Carp::croak 'Missing required attribute: segment_id' unless $segment_id;
    Carp::croak 'Invalid value for customers_ids'        unless ref $customers_ids eq 'ARRAY';

    return $self->tracking_request(
        POST => "segments/$segment_id/remove_customers",
        {ids => $customers_ids});
}

=head2 get_customers_by_email

Query Customer.io API for list of clients, who has requested email address.

usage: c<< get_customers_by_email($email)->future([$customer_obj1, ...]) >>

=cut

sub get_customers_by_email {
    my ($self, $email) = @_;

    Carp::croak 'Missing required argument: email' unless $email;

    return $self->api_request(GET => "customers?email=" . uri_escape_utf8($email))->then(
        sub {
            my ($resp) = @_;

            if (ref $resp ne 'HASH' || ref $resp->{results} ne 'ARRAY') {
                return Future->fail('UNEXPECTED_RESPONSE_FORMAT', 'customerio', 'Unexpected response format is recived', $resp);
            }

            try {
                my @customers = map { WebService::Async::CustomerIO::Customer->new($_->%*, api_client => $self) } $resp->{results}->@*;
                return Future->done(\@customers);
            } catch ($e) {
                return Future->fail('UNEXPECTED_RESPONSE_FORMAT', 'customerio', $e, $resp);
            }

        });
}

1;
