use strict;
use warnings;
use Test::More;
use URI;

BEGIN {
    package Uniform::HTTP::Request;
    sub new {
        my ($class, %args) = @_;
        return bless \%args, $class;
    }
    $INC{'Uniform/HTTP/Request.pm'} = __FILE__;

    package URLFast::Transaction;
    sub is_error { 0 }
    sub is_cancelled { 0 }
    sub is_complete { $_[0]{finished} || 0 }
    sub error { undef }
    sub finish {
        my ($self) = @_;
        die 'finished twice' if $self->{finished}++;
        $self->{callbacks}{on_finish}->($self);
    }

    package URLFast::Engine;
    our @REQUESTS;
    sub new { bless { closed => 0 }, shift }
    sub is_closed { $_[0]{closed} }
    sub request {
        my ($self, $req, %callbacks) = @_;
        push @REQUESTS, $req;
        return bless { callbacks => \%callbacks }, 'URLFast::Transaction';
    }

    package Unblock::HTTP1::Client;
    our @ISA = ('URLFast::Engine');
    $INC{'Unblock/HTTP1/Client.pm'} = __FILE__;

    package URLFast::Transport;
    sub new { bless {}, shift }
    sub unblock_send { 1 }
    sub unblock_finish { 1 }
    sub unblock_abort { 1 }
}
use Unblock::HTTP::Client;

my @deferred;
my $client = Unblock::HTTP::Client->new(
    http1 => {},
    defer => sub { push @deferred, $_[0] },
    connect_stream => sub {
        my ($origin, $protocols, $ready) = @_;
        $ready->(transport => URLFast::Transport->new, alpn => 'http/1.1');
    },
);
my $original_uri_new = URI->can('new');

sub check_url {
    my ($url, $expect_fast, $description) = @_;
    my $expected = $original_uri_new->('URI', $url);
    my $scheme = lc($expected->scheme || '');
    my $host = $expected->host;
    my $port = $expected->port;
    my $target = $expected->path_query;
    $target = '/' unless defined($target) && length($target);
    $target = '/' . $target if substr($target, 0, 1) eq '?';
    my $authority = $expected->authority;
    my $uses = 0;
    my $op;
    {
        no warnings 'redefine';
        local *URI::new = sub {
            ++$uses;
            goto &$original_uri_new;
        };
        $op = $client->request(
            method => 'GET', url => $url, http_version => '1.1',
        );
    }
    ok($op && $op->transaction, "$description admitted");
    my $request = $URLFast::Engine::REQUESTS[-1];
    is_deeply(
        [@{$request}{qw(scheme authority target)}],
        [$scheme, $authority, $target],
        "$description fields match URI",
    );
    is($uses, $expect_fast ? 0 : 1,
        "$description " . ($expect_fast ? 'avoids URI' : 'uses URI fallback'));
    my $key = join('|', $scheme, lc($host), $port);
    ok(exists($client->{pools}{$key}), "$description pool key matches URI");
    $op->transaction->finish;
    is($op->state, 'complete', "$description completes");
}

check_url('https://localhost/profile', 1, 'ordinary HTTPS path');
check_url('https://localhost/profile?req=12', 1, 'unique URL pattern');
check_url('http://example.org', 1, 'implicit HTTP slash');
check_url('https://example.org?x=1', 1, 'query without path');
check_url('https://example.org:443/path', 1, 'explicit default port');
check_url('http://1.2.3.4:8080/foo', 1, 'IPv4 custom port');
check_url('https://a.example/path?x=1&y=two+three', 1, 'query parameters');
check_url('https://foo-bar.org/thing-v2', 1, 'hyphenated hostname/path');
check_url('http://ab:65535/test', 1, 'highest legal port');
check_url('http://a/?', 1, 'empty query');
check_url('http://a//x?foo', 1, 'double slash in path');
check_url('http://a./', 0, 'trailing-dot hostname');
check_url('http://a:080/foo', 0, 'noncanonical port notation');
check_url('https://example.com/x%20y', 0, 'percent-encoded URL');
check_url('https://EXAMPLE.COM/', 0, 'mixed-case hostname');
check_url('HTTPS://example.com/path', 0, 'uppercase scheme');
check_url('https://[::1]/path', 0, 'IPv6 address');

for my $bad (
    ['https://example.org/path#fragment', qr/userinfo or a fragment/],
    ['https://user:pass@example.org/', qr/userinfo or a fragment/],
    ['http://example.org:0/path', qr/invalid URL port/],
    ['https://example.org:65536/path', qr/invalid URL port/],
    ['ftp://example.org/path', qr/scheme must be http or https/],
) {
    my ($url, $reason) = @$bad;
    my $ok = eval { $client->request(url => $url); 1 };
    ok(!$ok && $@ =~ $reason, "invalid $url retains rejection");
}
is(scalar @deferred, 0, 'fast paths do not create needless deferrals');
done_testing;
