#!/usr/bin/env perl
# Attempt to produce all errors for CGI backend

use warnings;
use strict;

use Test::More;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::SOAP::Util ':soap11';
my $soapenv = SOAP11ENV;

BEGIN
{   eval "require Plack";
    my $has_plack = $@ ? 0 : 1;

    plan skip_all => "Plack is needed"
        unless $has_plack;

    eval "use XML::Compile::SOAP::Daemon::PSGI";
    die $@ if $@;
}

plan tests => 14;

require_ok('Plack::Test');
require_ok('HTTP::Request');
require_ok('HTTP::Headers');

my $daemon = XML::Compile::SOAP::Daemon::PSGI->new;
isa_ok($daemon, 'XML::Compile::SOAP::Daemon::PSGI');

my $app = $daemon->to_app;
isa_ok($app, 'CODE');

sub compare_answer($$$)
{   my ($answer, $expected, $text) = @_;
    $answer =~ s/\r\n/\n/g;
    my @answer = split /\n/, $answer;
    my ($code, $msg, $ct) = @answer[0,1,2];
    my ($header, $content) = split /\n\n/, $answer;
    $content =~ s/( error\:) .*\z/$1 LIBXML-ERROR\n/s;

    my $a = join "\n", $code, $msg, $ct, '', $content;
    $a =~ s/\s*\z/\n/;

    is($a, $expected, $text);
}

###
### BEGIN
###

sub send_request($)
{   my $text = shift;
    my $answer = '';

    open my($fh), '<', \$text or die $!;

    my ($header, $body) = split /\n\n/, $text;
    my ($method, $url, $proto) = $header =~ /^(\S+)\s+(\S+)\s+([^\n]+)/; 
    my ($ct) = $header =~ m/^Content-Type\:\s+([^;\n]+)/im;
    my @header = split /\n/, $header;
    shift @header;
    my $h = HTTP::Headers->new( map { /^([^:]+):\s(.*)$/ && ($1 => $2) } @header );

    my $req = HTTP::Request->new( $method, $url, $h, $body );

    Plack::Test::test_psgi($app, sub {
        my $cb = shift;
        my $res = $cb->($req);
        my $msg = $res->headers->header('Warning') || '<empty>';
        $msg =~ s/^199 //;
        $answer = join "\n",
            $res->code,
            $msg,
            $res->content_type,
            '',
            $res->content;
    });
    return $answer;
}

### GET request

my $ans1 = send_request <<'__REQ1';
GET /a HTTP/1.0

__REQ1

compare_answer($ans1, <<__EXPECTED, 'not POST');
405
only POST or M-POST
text/plain

[405] attempt to connect via GET
__EXPECTED

### Non XML POST request

my $ans2 = send_request <<'__REQ2';
POST /a HTTP/1.0
Content-Type: text/plain

__REQ2

compare_answer($ans2, <<__EXPECTED, 'not XML');
406
required is XML
text/plain

[406] content-type seems to be text/plain, must be some XML
__EXPECTED

### XML parsing fails

my $ans4 = send_request <<'__REQ4';
POST /a HTTP/1.0
Content-Type: text/xml
soapAction: ''

<bad-xml>
__REQ4

compare_answer($ans4, <<__EXPECTED, 'parsing error');
422
XML syntax error
text/plain

[422] The XML cannot be parsed: error: LIBXML-ERROR
__EXPECTED

### Not SOAP Envelope

my $ans5 = send_request <<'__REQ5';
POST /a HTTP/1.0
Content-Type: text/xml
soapAction: ''

<not-soap></not-soap>
__REQ5

compare_answer($ans5, <<__EXPECTED, 'no soap envelope');
403
message not SOAP
text/plain

[403] The message was XML, but not SOAP; not an Envelope but `not-soap'
__EXPECTED

### Unknown SOAP Envelope

my $ans6 = send_request <<'__REQ6';
POST /a HTTP/1.0
Content-Type: text/xml
soapAction: ''

<me:Envelope xmlns:me="xx"></me:Envelope>
__REQ6

compare_answer($ans6, <<__EXPECTED, 'unknown soap envelope');
501
SOAP version not supported
text/plain

[501] The soap version `xx' is not supported
__EXPECTED


### Message not found

my $ans7 = send_request <<__REQ7;
POST /a HTTP/1.0
Content-Type: text/xml
soapAction: ''

<me:Envelope xmlns:me="$soapenv">
  <me:Body>
    <me:something />
  </me:Body>
</me:Envelope>
__REQ7

compare_answer($ans7, <<__EXPECTED, 'message not found');
404
message not recognized
text/xml

<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP-ENV:Body>
    <SOAP-ENV:Fault>
      <faultcode>SOAP-ENV:Server.notRecognized</faultcode>
      <faultstring>SOAP11 there are no handlers available, so also not for {http://schemas.xmlsoap.org/soap/envelope/}something</faultstring>
      <faultactor>http://schemas.xmlsoap.org/soap/actor/next</faultactor>
    </SOAP-ENV:Fault>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
__EXPECTED


my $daemon2 = XML::Compile::SOAP::Daemon::PSGI->new;
isa_ok($daemon2, 'XML::Compile::SOAP::Daemon::PSGI');

$app = $daemon2->run({preprocess => sub { die "BOOM\n" }});
isa_ok($app, 'CODE');

### Internal error

my $ans8 = send_request <<__REQ8;
POST /a HTTP/1.0
Content-Type: text/xml
soapAction: ''

<me:Envelope xmlns:me="$soapenv">
  <me:Body>
    <me:something />
  </me:Body>
</me:Envelope>
__REQ8

compare_answer($ans8, <<__EXPECTED, 'internal error');
500
<empty>
text/plain

BOOM
__EXPECTED
