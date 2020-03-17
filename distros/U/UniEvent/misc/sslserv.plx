#!/usr/bin/perl
use 5.012;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Benchmark qw/timethis timethese/;
use Data::Dumper qw/Dumper/;
use UniEvent qw/:const addrinfo_hints inet_pton inet_ntop inet_ptos inet_stop/;
use Devel::Peek;
use B::Concise;
use Net::SSLeay;
use Socket ':all';

sub sslerr ();

say "START $$";
my $d = UniEvent::Loop->default_loop();
my $i = 0;
my $port = shift or die "no port";
my @clients;

my $server = new UniEvent::TCP();
$server->bind("*", $port);
$server->listen(128, \&new_connection);

my $ctx = Net::SSLeay::CTX_new();
Net::SSLeay::CTX_set_verify($ctx, Net::SSLeay::VERIFY_PEER(), sub {
    say "VERIFY CALLBACK";
});
Net::SSLeay::CTX_use_certificate_file($ctx, "cppTests/cert.pem", &Net::SSLeay::FILETYPE_PEM) or sslerr();
Net::SSLeay::CTX_use_PrivateKey_file($ctx, "cppTests/key.pem", &Net::SSLeay::FILETYPE_PEM) or sslerr();
Net::SSLeay::CTX_check_private_key($ctx) or sslerr();
$server->use_ssl($ctx);

say "ENTERING LOOP";
$d->run;
say "LOOP DONE";

sub new_connection {
    my ($server, $err) = @_;
    say "new_connection";
    say $err if $err;
    my $client = new UniEvent::TCP;
    $server->accept($client);
    $client->read_callback(\&client_read);
    $client->eof_callback(\&client_eof);
    push @clients, $client;
    $client->ssl_connection_callback(sub {
        my ($h, $err) = @_;
        say $err if $err;
        say "on_ssl_connection";
    });
}

sub client_read {
    my ($client, $data, $err) = @_;
    say "client_read";
    say $err if $err;
    say "DATA=$data";
    $client->ssl_renegotiate();
    say "renegotiate called";
}

sub client_eof {
    my $client = shift;
    say "client_eof";
    @clients = grep { $_ ne $client } @clients;
}

sub sslerr () {
    my $rv = Net::SSLeay::ERR_get_error();
    die Net::SSLeay::ERR_error_string($rv);
}