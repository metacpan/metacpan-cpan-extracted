package WebService::WAservix;

use strict;
use warnings;

use Carp qw(croak);
use HTTP::Tiny;
use JSON::PP;

our $VERSION = '1.001';

my $DEFAULT_BASE_URL = 'https://tekservix.com/waservix/api';

sub new {
    my ($class, %args) = @_;
    croak 'WebService::WAservix: api_key is required (Devices -> API key in the WAservix dashboard)'
        unless defined $args{api_key} && length $args{api_key};
    my $base = $args{base_url} // $DEFAULT_BASE_URL;
    $base =~ s{/+\z}{};
    return bless {
        api_key  => $args{api_key},
        base_url => $base,
        json     => JSON::PP->new->utf8->canonical,
        http     => $args{http} // HTTP::Tiny->new(
            agent      => "waservix-perl/$VERSION",
            timeout    => $args{timeout} // 30,
            verify_SSL => 1,
        ),
    }, $class;
}

sub base_url { $_[0]{base_url} }

# Call any documented endpoint. Returns the decoded `data` field; dies with a
# WebService::WAservix::Error on failure (a 503 means the number is reconnecting).
sub request {
    my ($self, $method, $path, $body) = @_;
    my %headers = (
        'Authorization' => "Bearer $self->{api_key}",
        'Accept'        => 'application/json',
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
        die WebService::WAservix::Error->new(
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

# Send any message type. Fields use the API names: text, imageUrl, videoUrl, audioUrl,
# documentUrl, fileName, stickerUrl, contact, location, poll, replyTo, mentions, viewOnce.
sub send_message {
    my ($self, $to, %fields) = @_;
    croak 'send_message: "to" is required (international number or group JID)' unless defined $to && length $to;
    my %body = map { $_ => $fields{$_} } grep { defined $fields{$_} } keys %fields;
    $body{to} = $to;
    return $self->request('POST', '/send-message', \%body);
}

sub send_text { my ($self, $to, $text) = @_; $self->send_message($to, text => $text) }

sub send_image {
    my ($self, $to, $image_url, %opt) = @_;
    return $self->send_message($to, imageUrl => $image_url, text => $opt{caption});
}

sub send_document {
    my ($self, $to, $document_url, %opt) = @_;
    return $self->send_message($to, documentUrl => $document_url, fileName => $opt{file_name}, text => $opt{caption});
}

sub send_location {
    my ($self, $to, $latitude, $longitude, %opt) = @_;
    my %location = (latitude => $latitude + 0, longitude => $longitude + 0);
    $location{name} = $opt{name} if defined $opt{name};
    return $self->send_message($to, location => \%location);
}

sub get_message_info { $_[0]->request('GET',    '/messages/' . _esc($_[1]) . '/info') }
sub edit_message     { $_[0]->request('PUT',    '/messages/' . _esc($_[1]), { text => $_[2] }) }
sub delete_message   { $_[0]->request('DELETE', '/messages/' . _esc($_[1])) }
sub resend_message   { $_[0]->request('POST',   '/messages/' . _esc($_[1]) . '/resend') }

sub on_whatsapp   { $_[0]->request('GET', '/on-whatsapp/' . _esc($_[1])) }
sub get_status    { $_[0]->request('GET', '/status') }
sub get_user      { $_[0]->request('GET', '/user') }
sub list_contacts { $_[0]->request('GET', '/contacts') }
sub get_contact   { $_[0]->request('GET', '/contacts/' . _esc($_[1])) }
sub save_contact  { $_[0]->request('PUT', '/contacts', { phone => $_[1], name => $_[2] }) }
sub list_groups   { $_[0]->request('GET', '/groups') }
sub get_group_metadata { $_[0]->request('GET', '/groups/' . _esc($_[1]) . '/metadata') }

sub list_sessions  { $_[0]->request('GET', '/whatsapp-sessions') }
sub get_session    { $_[0]->request('GET', '/whatsapp-sessions/' . _esc($_[1])) }
sub create_session { $_[0]->request('POST', '/whatsapp-sessions', $_[1] // {}) }

sub connect_session {
    my ($self, $id, %opt) = @_;
    my $body = defined $opt{phone} ? { method => 'code', phone => $opt{phone} } : { method => 'qr' };
    return $self->request('POST', '/whatsapp-sessions/' . _esc($id) . '/connect', $body);
}

sub get_session_qr_code { $_[0]->request('GET', '/whatsapp-sessions/' . _esc($_[1]) . '/qrcode') }

# Constant-time check of the X-Webhook-Signature header against the number's webhook secret.
sub verify_webhook {
    my ($signature, $secret) = @_;
    ($signature, $secret) = @_[1, 2] if defined $signature && $signature eq __PACKAGE__;
    return 0 unless defined $signature && length $signature && defined $secret && length $secret;
    return 0 unless length $signature == length $secret;
    my $diff = 0;
    $diff |= ord(substr $signature, $_, 1) ^ ord(substr $secret, $_, 1) for 0 .. length($secret) - 1;
    return $diff == 0 ? 1 : 0;
}

sub _esc {
    my $s = shift // '';
    $s =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord $1)/ge;
    return $s;
}

package WebService::WAservix::Error;

use overload '""' => sub { 'WAservix: ' . $_[0]{message} . ' (HTTP ' . $_[0]{status} . ')' }, fallback => 1;

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

WebService::WAservix - WAservix WhatsApp API Gateway: official Perl client by Tekservix (send WhatsApp messages from your own number)

=head1 SYNOPSIS

    use WebService::WAservix;

    my $wa = WebService::WAservix->new(api_key => $ENV{WASERVIX_KEY});

    my $res = $wa->send_text('+15551234567', 'Hello Aline, your order is ready');
    print "Queued message $res->{msgId}\n";   # status starts as "in_progress"

    $wa->send_document('+15551234567', 'https://example.com/inv-1042.pdf',
        file_name => 'Invoice-1042.pdf', caption => 'Your invoice');

=head1 DESCRIPTION

L<WAservix|https://tekservix.com/waservix/> links your own WhatsApp number by QR code
(the same way WhatsApp Web does) and gives you a REST API to send text, images, documents,
locations, polls and more, with webhooks for incoming messages.

You need a Tekservix account with WAservix and the API key of your number (Devices in the
dashboard). Keep the key on your server. API reference: L<https://tekservix.com/waservix/docs/>.

WAservix is not Meta's official WhatsApp Business Platform: WhatsApp's spam rules apply to
your number directly, so message people who expect to hear from you.

Uses only core modules (L<HTTP::Tiny>, L<JSON::PP>); HTTPS needs L<IO::Socket::SSL>.

=head1 METHODS

All methods return the decoded C<data> part of the answer and die with a
L</WebService::WAservix::Error> object on failure.

=head2 new(api_key => $key, [base_url => $url], [timeout => 30], [http => $http_tiny])

=head2 send_message($to, %fields)

Any message type to a number or group JID (C<...@g.us>), with the API field names.
Returns C<< { msgId => ..., jid => ..., status => 'in_progress' } >>.

=head2 send_text($to, $text), send_image($to, $url, [caption => $text]), send_document($to, $url, [file_name => $name], [caption => $text]), send_location($to, $lat, $lng, [name => $name])

=head2 get_message_info($id), edit_message($id, $text), delete_message($id), resend_message($id)

=head2 on_whatsapp($phone), get_status, get_user

=head2 list_contacts, get_contact($phone), save_contact($phone, $name), list_groups, get_group_metadata($jid)

=head2 list_sessions, get_session($id), create_session(\%params), connect_session($id, [phone => $phone]), get_session_qr_code($id)

Session management needs a personal access token instead of a device key.

=head2 request($method, $path, [$body])

Calls any documented endpoint.

=head2 verify_webhook($signature, $secret)

Constant-time check of the C<X-Webhook-Signature> header against your number's webhook
secret. Can be called as a function or a class method.

=head1 WebService::WAservix::Error

Has C<status>, C<message>, C<errors>, C<body> and C<retry_after>. A 503 means the number is
reconnecting: retry shortly.

=head1 SEE ALSO

L<WebService::SmsGora> (SMS through your own Android phones),
L<https://tekservix.com/ai-sales-agent> (AI Sales Agent),
L<https://tekservix.com/mobile-apps> (Website to App).

=head1 AUTHOR

Tekservix E<lt>support@tekservix.comE<gt>

=head1 LICENSE

MIT. See the LICENSE file.

=cut
