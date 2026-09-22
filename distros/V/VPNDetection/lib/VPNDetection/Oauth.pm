package VPNDetection::Oauth;

use strict;
use warnings;

use B ();
use Carp ();
use Mojo::Promise;
use Mojo::Util ();
use Scalar::Util ();

use VPNDetection::Error;
use VPNDetection::OauthError;

our $VERSION = '3.3.1';

use constant DEVICE_CODE_GRANT => 'urn:ietf:params:oauth:grant-type:device_code';

# Each member a response may carry, by wire name: its type, whether it is
# required, and the name it is surfaced under when that differs.
my %METADATA = (
    issuer => ['string', 1],
    authorization_endpoint => ['string', 1],
    token_endpoint => ['string', 1],
    device_authorization_endpoint => ['string'],
    revocation_endpoint => ['string'],
    scopes_supported => ['list'],
    response_types_supported => ['list'],
    grant_types_supported => ['list'],
    code_challenge_methods_supported => ['list'],
    token_endpoint_auth_methods_supported => ['list'],
    authorization_response_iss_parameter_supported => ['bool'],
    service_documentation => ['string'],
);
my %DEVICE_AUTHORIZATION = (
    device_code => ['string', 1],
    user_code => ['string', 1],
    verification_uri => ['string', 1],
    verification_uri_complete => ['string'],
    expires_in => ['int', 1],
    interval => ['int', 1],
);
my %TOKEN_RESPONSE = (
    access_token => ['string', 1],
    token_type => ['string', 1],
    expires_in => ['int', 1],
    refresh_token => ['string'],
    scope => ['string'],
    'mslm:apikey_id' => ['string', 0, 'apikey_id'],
    'mslm:apikey' => ['string', 0, 'apikey'],
);

# The authorization server's discovery document. No call here needs it: each
# builds on the client's base URL.
sub metadata {
    my $self = shift;
    $self->_assert_blocking_ok('metadata');
    return $self->{client}->_wait($self->metadata_p(@_));
}

sub metadata_p {
    my ($self, %options) = @_;
    $self->{client}->_check_options('oauth->metadata', \%options, 'timeout');
    my $path = '/.well-known/oauth-authorization-server';
    return $self->_send_p($path, undef, $self->{client}{retries}, \%options)
        ->then(sub { _members(shift, \%METADATA) });
}

# Starts a device sign-in. It consumes nothing, so it is retried like a lookup.
sub device_authorization {
    my $self = shift;
    $self->_assert_blocking_ok('device_authorization');
    return $self->{client}->_wait($self->device_authorization_p(@_));
}

sub device_authorization_p {
    my ($self, $client_id, %options) = @_;
    _assert_argument('device_authorization', client_id => $client_id);
    $self->{client}->_check_options('oauth->device_authorization', \%options, 'scope', 'resource', 'timeout');
    my %form = (client_id => $client_id);
    for my $name (qw(scope resource)) {
        next unless defined $options{$name} && length $options{$name};
        _assert_argument('device_authorization', $name => $options{$name});
        $form{$name} = $options{$name};
    }
    return $self->_send_p('/oauth/device_authorization', \%form, $self->{client}{retries}, \%options)
        ->then(sub { _members(shift, \%DEVICE_AUTHORIZATION) });
}

# Asks once whether the person approved. Never retried: an approved code is
# spent by the answer carrying the tokens, so a retry could only lose them.
sub exchange_device_code {
    my $self = shift;
    $self->_assert_blocking_ok('exchange_device_code');
    return $self->{client}->_wait($self->exchange_device_code_p(@_));
}

sub exchange_device_code_p {
    my ($self, $client_id, $device_code, %options) = @_;
    _assert_argument('exchange_device_code', client_id => $client_id, device_code => $device_code);
    $self->{client}->_check_options('oauth->exchange_device_code', \%options, 'timeout');
    return $self->_exchange_p({
        grant_type => DEVICE_CODE_GRANT, device_code => $device_code, client_id => $client_id,
    }, \%options);
}

# The refresh token presented is spent whatever happens next, so this is never
# retried either.
sub exchange_refresh_token {
    my $self = shift;
    $self->_assert_blocking_ok('exchange_refresh_token');
    return $self->{client}->_wait($self->exchange_refresh_token_p(@_));
}

sub exchange_refresh_token_p {
    my ($self, $client_id, $refresh_token, %options) = @_;
    _assert_argument('exchange_refresh_token', client_id => $client_id, refresh_token => $refresh_token);
    $self->{client}->_check_options('oauth->exchange_refresh_token', \%options, 'timeout');
    return $self->_exchange_p({
        grant_type => 'refresh_token', refresh_token => $refresh_token, client_id => $client_id,
    }, \%options);
}

# The server answers the same for any token, so the body is never read.
sub revoke {
    my $self = shift;
    $self->_assert_blocking_ok('revoke');
    $self->{client}->_wait($self->revoke_p(@_));
    return;
}

sub revoke_p {
    my ($self, $client_id, $token, %options) = @_;
    _assert_argument('revoke', client_id => $client_id, token => $token);
    $self->{client}->_check_options('oauth->revoke', \%options, 'timeout');
    my %form = (token => $token, client_id => $client_id);
    return $self->_send_p('/oauth/revoke', \%form, $self->{client}{retries}, \%options)->then(sub { return });
}

sub poll_device_token {
    my $self = shift;
    $self->_assert_blocking_ok('poll_device_token');
    return $self->{client}->_wait($self->poll_device_token_p(@_));
}

sub poll_device_token_p {
    my ($self, $client_id, $device, %options) = @_;
    _assert_argument('poll_device_token', client_id => $client_id);
    Carp::croak('VPNDetection::oauth->poll_device_token: expected the device authorization hash')
        unless ref $device eq 'HASH' && defined $device->{device_code} && length $device->{device_code};
    $self->{client}->_check_options('oauth->poll_device_token', \%options, 'timeout');
    my $interval = $device->{interval};
    my $poll = {
        client_id => $client_id,
        device_code => $device->{device_code},
        options => \%options,
        interval => defined $interval && $interval >= 1 ? $interval : 5,
        deadline => $self->{now}->() + ($device->{expires_in} || 0),
    };
    return $self->_poll_p($poll);
}

sub _new {
    my ($class, $client) = @_;
    return bless {
        client => $client,
        # The poll's clock and its wait, replaced together in tests.
        now => \&Mojo::Util::steady_time,
        sleep_p => sub { Mojo::Promise->timer(shift) },
    }, $class;
}

# One wait, then one exchange. Recurses through $self rather than a
# self-referential closure, which would be a cycle the interpreter never collects.
sub _poll_p {
    my ($self, $poll) = @_;
    return $self->{sleep_p}->($poll->{interval})->then(sub {
        die VPNDetection::OauthExpiredTokenError->new(error_code => 'expired_token')
            if $self->{now}->() >= $poll->{deadline};
        return $self->_exchange_p({
            grant_type => DEVICE_CODE_GRANT,
            device_code => $poll->{device_code},
            client_id => $poll->{client_id},
        }, $poll->{options})->catch(sub {
            my $error = shift;
            die $error unless Scalar::Util::blessed($error) && $error->isa('VPNDetection::OauthError');
            # RFC 8628: slow_down widens the interval for every later request, not just the next.
            if ($error->error_code eq 'slow_down') {
                $poll->{interval} += 5;
            }
            elsif ($error->error_code ne 'authorization_pending') {
                die $error;
            }
            return $self->_poll_p($poll);
        });
    });
}

sub _exchange_p {
    my ($self, $form, $options) = @_;
    return $self->_send_p('/oauth/token', $form, 0, $options)
        ->then(sub { _members(shift, \%TOKEN_RESPONSE) });
}

# Every OAuth request goes through here, and none carries the API key: they are
# built with build_tx directly, never through the client's _headers.
sub _send_p {
    my ($self, $path, $form, $retries, $options) = @_;
    my $client = $self->{client};
    my $url = $client->_url($path);
    return $client->_retry_p($retries, sub {
        my $ua = $client->{ua};
        my %headers = (Accept => 'application/json');
        # Mojo's form generator sends a `+` in a value as %2B and a space as `+`.
        my $tx = defined $form
            ? $ua->build_tx(POST => $url => \%headers => form => $form)
            : $ua->build_tx(GET => $url => \%headers);
        return $client->_start_p($tx, $options->{timeout})->then(sub { _refusal(shift->res) });
    });
}

# Only a 4xx whose body is a JSON object with a STRING `error` is an OAuth
# refusal. Every 5xx, whatever it says, is the server failing, and is retried
# wherever the operation retries.
sub _refusal {
    my ($res) = @_;
    return $res if $res->is_success;
    my $body = $res->json;
    my $error = VPNDetection::Error->from_response($res->code, $res->headers, $body);
    die $error if $res->code >= 500 || ref $body ne 'HASH' || !_is_string($body->{error});
    die VPNDetection::OauthError->_from(
        error_code => $body->{error},
        error_description => _is_string($body->{error_description}) ? $body->{error_description} : undef,
        status => $res->code,
        kind => $error->kind,
    );
}

# The declared members that are present, each checked against its type, so an
# absent one has no key at all and an empty `scope` is present. Anything else the
# server sends is dropped.
sub _members {
    my ($res, $members) = @_;
    my $body = $res->json;
    die VPNDetection::Error->new(
        kind => 'server_error', status => $res->code,
        message => 'the API did not answer with a JSON object',
    ) unless ref $body eq 'HASH';

    my %present;
    for my $wire (sort keys %$members) {
        my ($type, $required, $name) = @{ $members->{$wire} };
        my $value = $body->{$wire};
        if (!defined $value) {
            die VPNDetection::Error->new(
                kind => 'server_error', status => $res->code, message => "the answer carried no $wire",
            ) if $required;
            next;
        }
        my $valid = $type eq 'string' ? _is_string($value)
            : $type eq 'int' ? !ref $value && !_is_string($value) && $value =~ /\A-?[0-9]+\z/
            : $type eq 'bool' ? Scalar::Util::blessed($value) && $value->isa('JSON::PP::Boolean')
            : ref $value eq 'ARRAY' && !grep { !_is_string($_) } @$value;
        die VPNDetection::Error->new(
            kind => 'server_error', status => $res->code, message => "the answer's $wire is not a $type",
        ) unless $valid;
        $present{ defined $name ? $name : $wire } = $type eq 'bool' ? ($value ? 1 : 0) : $value;
    }
    return \%present;
}

# A JSON string rather than a number: Mojo::JSON decodes the two into different
# kinds of scalar, and nothing else in Perl tells `"7"` from `7`.
sub _is_string {
    my ($value) = @_;
    return 0 if !defined $value || ref $value;
    my $flags = B::svref_2object(\$value)->FLAGS;
    return ($flags & B::SVp_POK) && !($flags & (B::SVp_IOK | B::SVp_NOK)) ? 1 : 0;
}

sub _assert_argument {
    my ($method, %arguments) = @_;
    for my $name (sort keys %arguments) {
        my $value = $arguments{$name};
        Carp::croak("VPNDetection::oauth->$method: expected $name as a string")
            if !defined $value || ref $value || !length $value;
    }
}

sub _assert_blocking_ok {
    my ($self, $method) = @_;
    $self->{client}->_assert_blocking_ok("oauth->$method");
}

1;

__END__

=head1 NAME

VPNDetection::Oauth - sign a person in with the OAuth device flow

=head1 SYNOPSIS

    my $client = VPNDetection->new;

    my $device = $client->oauth->device_authorization('your-client-id',
        scope => 'account.read apikeys.read apikeys.reveal');
    print "Open $device->{verification_uri} and enter $device->{user_code}\n";

    my $token = $client->oauth->poll_device_token('your-client-id', $device);
    my $keyed = VPNDetection->new(api_key => $token->{apikey});

=head1 DESCRIPTION

A program running on the person's own machine lets them sign in with a browser
and pick one of their API keys, instead of asking them to paste it. Reached
through L<VPNDetection/oauth>.

Every method takes a client ID, issued on request from support@vpndetection.io.
None of these requests carries the client's API key, and none needs one. Every
method takes a per-call C<timeout> in seconds, bounding each request it sends,
and has a C<_p> twin returning a L<Mojo::Promise>.

Answers are hash references keyed by the wire names. A member the server did not
send has no key at all, and an empty C<scope> is present.

A refusal dies with a L<VPNDetection::OauthError>; anything else, a transport
failure or a server error, with the ordinary L<VPNDetection::Error>.

=head1 METHODS

=head2 metadata(%options)

The authorization server's discovery document: C<issuer>,
C<authorization_endpoint> and C<token_endpoint>, plus whichever of
C<device_authorization_endpoint>, C<revocation_endpoint>, C<scopes_supported>,
C<response_types_supported>, C<grant_types_supported>,
C<code_challenge_methods_supported>, C<token_endpoint_auth_methods_supported>,
C<authorization_response_iss_parameter_supported> and C<service_documentation>
it carries.

=head2 device_authorization($client_id, %options)

Starts a device sign-in. C<scope> is space-delimited and sent as given, and
C<resource> names the API the tokens are for; both are left out when not given.
Returns C<device_code>, C<user_code>, C<verification_uri>, C<expires_in> and
C<interval>, and C<verification_uri_complete> when the server sends it. Show the
person C<user_code> and C<verification_uri>, then pass the hash to
C<poll_device_token>.

=head2 exchange_device_code($client_id, $device_code, %options)

Asks once whether the person approved. Until they do, it dies with an
L<VPNDetection::OauthError> coded C<authorization_pending>. Never retried.

=head2 exchange_refresh_token($client_id, $refresh_token, %options)

Trades a refresh token for a new pair. The one presented is spent, so keep the
C<refresh_token> each call returns. A refresh names the key the person picked
(C<apikey_id>) but never reveals it again (C<apikey>). Never retried.

Both exchanges return C<access_token>, C<token_type> and C<expires_in>, and
whichever of C<refresh_token>, C<scope>, C<apikey_id> and C<apikey> the server
sent. C<apikey_id> without C<apikey> is normal: the key itself also needs a
sign-in rather than a refresh, and a key whose secret can be shown again.

=head2 revoke($client_id, $token, %options)

Ends a token. A refresh token ends the whole sign-in and every token it issued,
which is how a program signs the machine out; an access token ends only itself.

=head2 poll_device_token($client_id, $device, %options)

Waits for the person to approve, and returns the tokens. It waits C<interval>
seconds (5 when that is below 1) before EVERY request, the first included, and 5
more for the rest of the call each time the server answers C<slow_down>. It ends
at the first answer that is neither: a denial dies with
C<VPNDetection::OauthAccessDeniedError>, a code that ran out with
C<VPNDetection::OauthExpiredTokenError> - as does outliving C<expires_in>, counted
from this call, with no C<status> - and any other failure as it came. The timeout
bounds each request, never the poll.

There is no cancellation handle: the blocking form returns only at one of those
outcomes. The waits are event-loop timers, so C<poll_device_token_p> shares a
running L<Mojo::IOLoop> with everything else on it.

=cut
