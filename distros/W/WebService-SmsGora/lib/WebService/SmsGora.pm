package WebService::SmsGora;

use strict;
use warnings;

use Carp qw(croak);
use Digest::SHA qw(hmac_sha256_hex);
use HTTP::Tiny;
use JSON::PP;

our $VERSION = '1.001';

my $DEFAULT_BASE_URL = 'https://tekservix.com/smsgora/api/v1';

sub new {
    my ($class, %args) = @_;
    croak 'WebService::SmsGora: api_key is required (create one in SMS Gora -> API keys)'
        unless defined $args{api_key} && length $args{api_key};
    my $base = $args{base_url} // $DEFAULT_BASE_URL;
    $base =~ s{/+\z}{};
    my $self = bless {
        api_key  => $args{api_key},
        base_url => $base,
        json     => JSON::PP->new->utf8->canonical,
        http     => $args{http} // HTTP::Tiny->new(
            agent      => "smsgora-perl/$VERSION",
            timeout    => $args{timeout} // 30,
            verify_SSL => 1,
        ),
    }, $class;
    return $self;
}

sub base_url { $_[0]{base_url} }

# Call any documented endpoint. Returns the decoded `data` field; dies with a
# WebService::SmsGora::Error on failure.
sub request {
    my ($self, $method, $path, $body) = @_;
    my %headers = (
        'x-api-key' => $self->{api_key},
        'Accept'    => 'application/json',
    );
    my %options = (headers => \%headers);
    if (defined $body) {
        $headers{'Content-Type'} = 'application/json';
        $options{content} = $self->{json}->encode($body);
    }

    my $res  = $self->{http}->request(uc $method, $self->{base_url} . $path, \%options);
    my $text = $res->{content} // '';
    my $json = eval { length $text ? $self->{json}->decode($text) : undef };

    my $failed = ref $json eq 'HASH' && exists $json->{success} && !$json->{success};
    if (!$res->{success} || $failed) {
        my $status = $res->{status};
        die WebService::SmsGora::Error->new(
            status      => $status == 599 ? 0 : $status,
            message     => (ref $json eq 'HASH' && defined $json->{message}) ? $json->{message}
                         : $status == 599 ? "request failed: $text"
                         : "HTTP $status",
            errors      => ref $json eq 'HASH' ? $json->{errors} : undef,
            body        => $json // $text,
            retry_after => $res->{headers}{'retry-after'},
        );
    }
    return (ref $json eq 'HASH' && exists $json->{data}) ? $json->{data} : $json;
}

sub send_sms {
    my ($self, %args) = @_;
    my @to = ref $args{to} eq 'ARRAY' ? @{ $args{to} } : grep { length } split /\s*,\s*/, ($args{to} // '');
    croak 'send_sms: at least one recipient is required' unless @to;
    croak 'send_sms: message is required' unless defined $args{message};

    my %body = (recipients => \@to, message => $args{message});
    $body{sim_slot}    = $args{sim_slot} + 0 if defined $args{sim_slot};
    $body{schedule_at} = $args{schedule_at} if defined $args{schedule_at};
    my $path = defined $args{device_id} ? '/devices/' . _esc($args{device_id}) . '/send-sms' : '/send-sms';
    return $self->request('POST', $path, \%body);
}

sub send_bulk_sms {
    my ($self, $device_id, %args) = @_;
    my %body = (messages => $args{messages} // []);
    $body{messageTemplate} = $args{message_template} if defined $args{message_template};
    return $self->request('POST', '/devices/' . _esc($device_id) . '/send-bulk-sms', \%body);
}

sub get_message    { $_[0]->request('GET',  '/messages/' . _esc($_[1])) }
sub cancel_message { $_[0]->request('POST', '/messages/' . _esc($_[1]) . '/cancel') }

sub list_messages {
    my ($self, %filters) = @_;
    return $self->request('GET', '/messages' . _query(%filters));
}

sub list_received_sms {
    my ($self, %filters) = @_;
    my $device_id = delete $filters{device_id};
    my $path = defined $device_id ? '/devices/' . _esc($device_id) . '/get-received-sms' : '/received-sms';
    return $self->request('GET', $path . _query(%filters));
}

sub get_batch    { $_[0]->request('GET', '/batches/' . _esc($_[1])) }
sub list_devices { $_[0]->request('GET', '/devices') }
sub get_device   { $_[0]->request('GET', '/devices/' . _esc($_[1])) }
sub get_account  { $_[0]->request('GET', '/account') }
sub list_webhooks { $_[0]->request('GET', '/webhooks') }

sub create_webhook {
    my ($self, %args) = @_;
    croak 'create_webhook: url is required' unless $args{url};
    return $self->request('POST', '/webhooks', {
        url       => $args{url},
        events    => $args{events} // ['sms.received'],
        device_id => $args{device_id},
    });
}

sub delete_webhook { $_[0]->request('DELETE', '/webhooks/' . _esc($_[1])) }

# Check the X-SmsGora-Signature header (sha256=<hex HMAC-SHA256 of the raw body>).
sub verify_webhook {
    my ($raw_body, $signature, $secret) = @_;
    ($raw_body, $signature, $secret) = @_[1 .. 3] if ref $raw_body || (defined $raw_body && $raw_body eq __PACKAGE__);
    return 0 unless defined $raw_body && length $raw_body && defined $signature && length $signature
        && defined $secret && length $secret;
    my $expected = 'sha256=' . hmac_sha256_hex($raw_body, $secret);
    return _secure_eq($expected, $signature);
}

sub _secure_eq {
    my ($a, $b) = @_;
    return 0 unless length $a == length $b;
    my $diff = 0;
    $diff |= ord(substr $a, $_, 1) ^ ord(substr $b, $_, 1) for 0 .. length($a) - 1;
    return $diff == 0 ? 1 : 0;
}

sub _esc {
    my $s = shift // '';
    $s =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord $1)/ge;
    return $s;
}

sub _query {
    my %params = @_;
    my @pairs = map { _esc($_) . '=' . _esc($params{$_}) }
        grep { defined $params{$_} && length $params{$_} } sort keys %params;
    return @pairs ? '?' . join('&', @pairs) : '';
}

package WebService::SmsGora::Error;

use overload '""' => sub { 'SmsGora: ' . $_[0]{message} . ' (HTTP ' . $_[0]{status} . ')' }, fallback => 1;

sub new         { my ($class, %args) = @_; return bless {%args}, $class }
sub status      { $_[0]{status} }
sub message     { $_[0]{message} }
sub errors      { $_[0]{errors} }
sub body        { $_[0]{body} }
sub retry_after { $_[0]{retry_after} }

1;

__END__

=encoding utf8

=head1 NAME

WebService::SmsGora - SMS Gora SMS Gateway: official Perl client by Tekservix (send and receive SMS through your own Android phones)

=head1 SYNOPSIS

    use WebService::SmsGora;

    my $sms = WebService::SmsGora->new(api_key => $ENV{SMSGORA_KEY});

    my $result = $sms->send_sms(to => '+15551234567', message => 'Your code is 482913');
    print "Queued: @{ $result->{message_ids} }\n";

    my $msg = $sms->get_message($result->{message_ids}[0]);
    print "Status: $msg->{status}\n";   # queued, dispatched, sent, delivered, failed

=head1 DESCRIPTION

L<SMS Gora|https://tekservix.com/smsgora/> turns Android phones with ordinary SIM cards
into an SMS gateway. Your server calls the API, a linked phone sends the text, and replies
and delivery reports come back to you by webhook.

You need a Tekservix account with SMS Gora and an API key (SMS Gora -> API keys). Keep the
key on your server. API reference: L<https://tekservix.com/smsgora/docs/>.

Uses only core modules (L<HTTP::Tiny>, L<JSON::PP>, L<Digest::SHA>); HTTPS needs
L<IO::Socket::SSL>.

=head1 METHODS

All methods return the decoded C<data> part of the answer and die with a
L</WebService::SmsGora::Error> object on failure.

=head2 new(api_key => $key, [base_url => $url], [timeout => 30], [http => $http_tiny])

=head2 send_sms(to => $number_or_arrayref, message => $text, [device_id => $id], [sim_slot => 0|1], [schedule_at => $iso8601])

Sends to up to 1,000 numbers. C<to> may be an array reference or a comma separated
string. Returns C<< { message_ids => [...] } >>.

=head2 send_bulk_sms($device_id, messages => [ { recipients => [...], message => $text }, ... ], [message_template => $text])

Different texts for different people in one call (up to 5,000 recipients).

=head2 get_message($id), cancel_message($id)

=head2 list_messages(%filters), list_received_sms([device_id => $id], %filters)

Filters: direction, status, phone, since, after_id, page, limit.

=head2 get_batch($id), list_devices, get_device($id), get_account

=head2 list_webhooks, create_webhook(url => $url, [events => [...]], [device_id => $id]), delete_webhook($id)

=head2 request($method, $path, [$body])

Calls any documented endpoint.

=head2 verify_webhook($raw_body, $signature, $secret)

Checks the C<X-SmsGora-Signature> header of an incoming webhook in constant time.
Can be called as a function or a class method. Pass the raw request body.

=head1 WebService::SmsGora::Error

Has C<status>, C<message>, C<errors>, C<body> and C<retry_after> (seconds, on 429).
Stringifies to a readable message.

=head1 SEE ALSO

L<WebService::WAservix> (WhatsApp from your own number),
L<https://tekservix.com/ai-sales-agent> (AI Sales Agent),
L<https://tekservix.com/mobile-apps> (Website to App).

=head1 AUTHOR

Tekservix E<lt>support@tekservix.comE<gt>

=head1 LICENSE

MIT. See the LICENSE file.

=cut
