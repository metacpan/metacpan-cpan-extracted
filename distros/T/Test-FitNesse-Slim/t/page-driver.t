#! perl

use strict;
use utf8;
use warnings;

use File::Temp qw(tempfile);
use IO::Socket::INET;
use lib "t/lib";
use Test::More;
use Fitnesse::Fixtures::ResponseContext;

my $listener = IO::Socket::INET->new(
  LocalAddr => "127.0.0.1",
  LocalPort => 0,
  Listen    => 5,
  Proto     => "tcp",
) or die "cannot create mock FitNesse listener: $!";
my $port = $listener->sockport;
my($capture,$capture_path) = tempfile(UNLINK => 1);
close $capture;

my $server_pid = fork();
die "fork mock FitNesse listener: $!" unless defined $server_pid;
if (!$server_pid) {
  open my $requests, ">", $capture_path or die "open request capture: $!";
  for (1 .. 6) {
    my $client = $listener->accept or die "accept mock FitNesse request: $!";
    binmode $client;
    my $request_line = <$client> // "";
    my $headers = "";
    my $content_length = 0;
    while (my $line = <$client>) {
      last if $line eq "\r\n" || $line eq "\n";
      $headers .= $line;
      $content_length = $1 if $line =~ /^Content-Length:\s*(\d+)/i;
    }
    my $body = "";
    while (length($body) < $content_length) {
      my $count = read $client, my($part), $content_length - length($body);
      last unless $count;
      $body .= $part;
    }
    print {$requests} "$request_line$headers\r\n$body\n---REQUEST---\n";

    my($status,$reason,$content) = (200,"OK","saved");
    if ($request_line =~ m{^GET /Probe\?test }) {
      $content = "line one\nneedle in line two\nlast line";
    }
    elsif ($request_line =~ m{^GET /Encoded\?test }) {
      $content = '<td>tear down after &lt;a href="MySuite.TestPageA"&gt;TestPageA&lt;/a&gt;</td>';
    }
    elsif ($request_line =~ m{^GET /Error\?test }) {
      ($status,$reason,$content) = (500,"Internal Server Error","<html>FitNesse error</html>");
    }
    my $bytes = length $content;
    print {$client} "HTTP/1.1 $status $reason\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: $bytes\r\nConnection: close\r\n\r\n$content";
    close $client;
  }
  close $requests;
  close $listener;
  exit 0;
}
close $listener;

$ENV{TEST_SLIM_FITNESSE_URL} = "http://127.0.0.1:$port";
require Fitnesse::Fixtures::PageDriver;

my $driver = Fitnesse::Fixtures::PageDriver->new;
isa_ok($driver, "Fitnesse::Fixtures::PageDriver");

is($driver->create_page_with_content("Probe", "Hello & snowman ☃"), undef,
  "page creation follows the upstream void method contract");
is($driver->make_a_test_page("Probe"), undef,
  "marking a page as a test follows the upstream void method contract");
is($driver->make_a_suite_page("Probe"), undef,
  "marking a page as a suite follows the upstream void method contract");
is($driver->request_page("Probe?test"), 200,
  "request_page returns the HTTP status from the nested test request");
is($driver->content, "line one\nneedle in line two\nlast line",
  "content retains the last HTTP response body");
is(Fitnesse::Fixtures::ResponseContext->current->{status}, 200,
  "the last response is available through the shared harness response context");
is($driver->content_contains("needle"), "true",
  "content_contains finds text in the retained response");
is($driver->content_contains("absent"), "false",
  "content_contains returns false for absent text");
is($driver->content_matches("needle.*two"), "true",
  "content_matches evaluates a multiline response pattern");
is($driver->line_number_containing("needle"), 1,
  "line_number_containing follows the upstream split-based line count");
is($driver->line_number_containing("last line"), 2,
  "line_number_containing counts non-trailing lines like the Java fixture");
is($driver->line_number_containing("absent"), -1,
  "line_number_containing returns -1 when the response does not contain the text");
is($driver->request_page("Encoded?test"), 200,
  "encoded response fixture is available for content inspection");
is($driver->content, '<td>tear down after &lt;a href="MySuite.TestPageA"&gt;TestPageA&lt;/a&gt;</td>',
  "content returns the original response markup");
is($driver->content_contains('<a href="MySuite.TestPageA">TestPageA</a>'), "true",
  "content_contains inspects HTML-unescaped response contents like upstream PageDriver");
is($driver->content_matches('tear down after <a href="MySuite\.TestPageA"'), "true",
  "content_matches uses the same decoded content source");

my $other = Fitnesse::Fixtures::PageDriver->new;
is($other->request_page("Error?test"), 500,
  "HTTP error responses return their status rather than being mistaken for success");
is($other->content, "<html>FitNesse error</html>",
  "HTTP error response bodies are retained for inspection");
is($driver->content, '<td>tear down after &lt;a href="MySuite.TestPageA"&gt;TestPageA&lt;/a&gt;</td>',
  "response state belongs to each PageDriver instance");

waitpid($server_pid, 0);
is($? >> 8, 0, "mock FitNesse server handled all requests");
open my $captured, "<", $capture_path or die "read request capture: $!";
local $/;
my $requests = <$captured>;
close $captured;
like($requests, qr/^POST \/Probe HTTP\/1\.1.*?responder=saveData/s,
  "create_page_with_content posts to the page save responder");
like($requests, qr/(?=.*editTime=9999999999999)(?=.*ticketId=321)(?=.*pageContent=Hello\+%26\+snowman\+%E2%98%83)(?=.*responder=saveData)/s,
  "page creation uses the installed PageDriver save fields and form encoding");
like($requests, qr/^POST \/Probe HTTP\/1\.1(?:(?!---REQUEST---).)*(?=.*responder=saveProperties)(?=.*PageType=Test)/ms,
  "make_a_test_page uses the FitNesse page properties responder");
like($requests, qr/^POST \/Probe HTTP\/1\.1(?:(?!---REQUEST---).)*(?=.*responder=saveProperties)(?=.*PageType=Suite)/ms,
  "make_a_suite_page uses the FitNesse page properties responder");
like($requests, qr/^GET \/Probe\?test HTTP\/1\.1/m,
  "request_page preserves the nested test responder URI");

my $closed_listener = IO::Socket::INET->new(
  LocalAddr => "127.0.0.1", LocalPort => 0, Listen => 1, Proto => "tcp",
) or die "cannot reserve offline port: $!";
my $closed_port = $closed_listener->sockport;
close $closed_listener;
my $offline = Fitnesse::Fixtures::PageDriver->new({
  base_url => "http://127.0.0.1:$closed_port",
});
my $transport_error = eval { $offline->request_page("Probe?test"); 1 } ? "" : $@;
like($transport_error, qr/FitNesse HTTP request failed:/,
  "transport failures are reported as fixture errors");
like($offline->content, qr/Can't connect|Connection refused/,
  "the transport failure details remain available in the response context");
is(Fitnesse::Fixtures::ResponseContext->current->{status}, 599,
  "transport failures are retained for other harness fixtures to inspect");

done_testing();
