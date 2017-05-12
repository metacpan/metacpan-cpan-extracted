package WebService::DNSMadeEasy::Client;

use Moo;
use DateTime;
use DateTime::Format::HTTP;
use Digest::HMAC_SHA1 qw(hmac_sha1 hmac_sha1_hex);
use DDP;

with qw/MooX::Singleton Role::REST::Client/;

has api_key           => (is => 'rw', required => 1);
has secret            => (is => 'rw', required => 1);
has user_agent_header => (is => 'rw', required => 1);
has sandbox           => (is => 'rw', default => sub { 0 });
has '+server'         => (builder => 1, lazy => 1);

sub _build_server {
    my ($self) = @_;
    return $self->sandbox
        ? "https://api.sandbox.dnsmadeeasy.com/V2.0"
        : "https://api.dnsmadeeasy.com/V2.0";
}

sub default_headers {
    my ($self, $date) = @_;

    $date //= DateTime->now->set_time_zone('GMT');
    my $date_string = DateTime::Format::HTTP->format_datetime($date);

    return (
        'x-dnsme-requestDate' => $date_string,
        'x-dnsme-apiKey'      => $self->api_key,
        'x-dnsme-hmac'        => hmac_sha1_hex($date_string, $self->secret),
        'accept'              => 'application/json',
    );
}

around qw/get put post delete/ => sub {
    my $orig = shift;
    my $self = shift;

    my $url  = $_[0];
    my $data = $_[1];

    my @caller_info = caller(2);
    my $sub = $caller_info[3];
    $sub =~ s/WebService::DNSMadeEasy::Client::(\w+)$/$1/;

    $self->set_header($self->default_headers);

    my $res = $orig->($self, @_);

    if ($res->failed) {
        my $res_data = eval { $res->data } // {};
        
        my $msg = sprintf "HTTP request failed\nRequest:  %s %s\nResponse: %s\n",
            uc $sub, $url, $res->response->status_line;

        die $msg . p($res_data) . "\n";
    }

    return $res;
};

1;
