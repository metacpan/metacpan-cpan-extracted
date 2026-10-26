use strict;
use warnings;
use Test::More;
use CPAN::Meta;

BEGIN {
    unshift @INC, sub {
        die "optional engine deliberately unavailable: $_[1]\n"
            if $_[1] =~ m{\A(?:Unblock/HTTP[23](?:/|\.pm)|Net/QUIC|Unblock/WebSocket)};
        return;
    };
}
use Unblock::HTTP::Server;
use Unblock::HTTP::Client;
use Unblock::HTTP::_EngineFactory;

{ package H1OnlyHost;
  sub new { bless { wire => '' }, shift }
  sub unblock_send { $_[0]{wire} .= $_[1]; 1 }
  sub unblock_finish { }
  sub unblock_abort { die $_[1] }
}
my $host = H1OnlyHost->new;
my $server = Unblock::HTTP::Server->new(http1 => {}, on_request => sub {
    $_[0]->respond(status => 200, body => 'h1 only');
});
my $engine = $server->attach_stream(transport => $host);
$engine->input("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n");
like($host->{wire}, qr/h1 only\z/, 'HTTP1 serves without optional engines');
my $client = Unblock::HTTP::Client->new(http1 => {}, defer => sub {},
    connect_stream => sub {});
isa_ok($client, 'Unblock::HTTP::Client');
ok(!grep(m{\A(?:Unblock/HTTP[23]|Net/QUIC|Unblock/WebSocket)}, keys %INC),
    'H1-only path never loads optional engines');
for my $protocol (qw(h2 h3)) {
    eval { Unblock::HTTP::_EngineFactory->create('Client', $protocol) };
    like($@, qr/enabled HTTP protocol '$protocol' requires Unblock::HTTP[23]::Client/,
        'explicit requested protocol has actionable missing-engine error');
}
my $meta = CPAN::Meta->load_file('MYMETA.json');
my $requires = $meta->effective_prereqs->requirements_for('runtime', 'requires');
is($requires->requirements_for_module('Unblock::HTTP1'), '0.13', 'HTTP1 remains required');
my %required = map { $_ => 1 } $requires->required_modules;
ok(!$required{'Unblock::HTTP2'} && !$required{'Unblock::HTTP3'}, 'H2/H3 are not mandatory dependencies');
for my $name (qw(http2 http3)) {
    ok($meta->feature($name), "$name optional feature is advertised");
}
done_testing;
