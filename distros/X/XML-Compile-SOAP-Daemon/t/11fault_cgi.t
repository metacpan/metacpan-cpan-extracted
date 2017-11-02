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
{   eval "require CGI";
    my $has_cgi = $@ ? 0 : 1;

    $has_cgi
        or plan skip_all => "CGI is required for these tests";
}

plan tests => 9;

require_ok('CGI');

use_ok('XML::Compile::SOAP::Daemon::CGI');

my $daemon = XML::Compile::SOAP::Daemon::CGI->new;
isa_ok($daemon, 'XML::Compile::SOAP::Daemon::CGI');

sub compare_answer($$$)
{   my ($answer, $expected, $text) = @_;
    $answer =~ s/\r\n/\n/g;
    my ($proto, $code, $msg) = $answer =~ m/^(\S+)\s+([0-9]+)\s+([^\n]+)/; 
    my ($header, $content) = split /\n\n/, $answer;

    # error not always the same for various libxml versions
    $content =~ s/( error\:) .*\z/$1 LIBXML-ERROR\n/s;

    my ($ct) = $header =~ m/^Content-Type\:\s+([^;\n]+)/im;
    my $a = join "\n", $code, $msg, $ct, '', $content;
    $a =~ s/\s*\z/\n/;

    is($a, $expected, $text);
}

###
### BEGIN
###

sub send_request($)
{   my $text = shift;
    open my($fh), '<', \$text or die $!;
    my $q = CGI->new($fh);

    my ($header, $body) = split /\n\n/, $text;
    my ($method, $url, $proto) = $header =~ m/^(\S+)\s+(\S+)\s+([^\n]+)/; 
    my ($ct) = $header =~ m/^Content-Type\:\s+([^;\n]+)/im;
    my $out  = '';
    {  local *STDOUT;
       open STDOUT, '>', \$out or die $!;
       local $ENV{REQUEST_METHOD} = $method;
       local $ENV{CONTENT_TYPE}   = $ct;
       $q->param(POSTDATA => $body);
       $daemon->_run({}, $q);
    }
    $out;
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
