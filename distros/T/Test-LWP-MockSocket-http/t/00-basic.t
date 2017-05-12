#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN {
    use_ok("Test::LWP::MockSocket::http");
}
use LWP::UserAgent;
use LWP::ConnCache;

sub genlong {
    my $s = "HTTP/1.1 200 OK\r\n";
    my $content = 'Long Text ' x 4000;
    $s .= "Content-Length: " . length($content) . "\r\n";
    $s .= "\r\n";
    $s .= $content;
    return ($s,[200, $content, "Long content"]);
}

my %RESPONSES = (
<<EOS,
HTTP/1.1 200 OK
Connection: close
Content-Length: 11

Hello World
EOS
=> [200, "Hello World", "Simple 200 OK"],

<<EOS,
HTTP/1.0 403 Forbidden
Content-Type: text/html

You cannot access this page
EOS

=> [403, "You cannot access this page\n", "HTTP 403 Forbidden"], #Implicit newline without Content-Length
<<EOS
HTTP/1.1 302 Found
Location: http://www.foo.com/bar/baz
Content-Length: 24

This page has been moved
EOS

=> [302, "This page has been moved", "HTTP 302 Redirect"],

genlong()
);


my $ua = LWP::UserAgent->new();

sub do_test {
    while (my ($k,$v) = each %RESPONSES) {
        #Select a proxy at random
        my $ip = join(".", map { int(rand(254)) } (0..3));
        my $timeout = int(rand(50));
        my $response = $k;
        my ($expected_code,$expected_content,$desc) = @$v;
        $LWP_Response = $response;
        $ua->proxy("http", "http://$ip");
        $ua->timeout($timeout);
        my $o = $ua->get("http://www.nonexistent.org");
        is($LWP_SocketArgs->{PeerAddr}, $ip, "IP matches");
        is($LWP_SocketArgs->{Timeout}, $timeout, "Timeout Matches");
        is($o->code, $expected_code, "Got $expected_code");
        is($o->content, $expected_content, "Got expected content, $desc");
    }
}

#Set up a connection cache?
do_test();
my $conn_cache = LWP::ConnCache->new(total_capacity => 20);
diag "Testing with LWP::ConnCache";
$ua->conn_cache($conn_cache);
do_test();

diag "Testing with more 'advanced' API";
my @sock_args;
mocksock_response(sub {
    my ($blob,$request,$sargs) = @_;
    push @sock_args, $sargs;
    return
        "HTTP/1.0 200 OK\r\n".
        "\r\n".
        scalar(reverse($request->uri));
});
$ua->use_eval(0);
$ua->proxy("http", undef);
my $resp = $ua->get("http://foo.org/xyz");
is($resp->content, "zyx/", "Response Generator Handler (1/4)");
$resp = $ua->get("http://bar.org/oof");
is($resp->content, "foo/", "Response Generator Handler (2/4)");

#bonus points
my $tmp = shift @sock_args;
is($tmp->{PeerAddr}, 'foo.org', "Response Generator Handler (socket args), (3/4)");
$tmp = shift @sock_args;
is($tmp->{PeerAddr}, 'bar.org', "Response Generator Handler (socket args), (3/4)");

my $response_base = "HTTP/1.0 200 OK\r\n\r\n";
mocksock_response([$response_base."First", $response_base."Second"]);
$resp = $ua->get("http://www.foo.com");
is($resp->content, "First", "Array (1/2)");
$resp = $ua->get("http://blah.org");
is($resp->content, "Second", "Array (2/2)");

done_testing();
