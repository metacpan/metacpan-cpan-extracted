#!/usr/bin/env perl
# This code is part of distribution XML-Compile-WSS-Signature.
# Meta-POD processed with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

# Check decoding and encoding of wsse:BinarySecurityToken

use warnings;
use strict;

use lib '../XML-Compile-WSS/lib', 'lib';

use Log::Report mode => 2;
use Test::More;

use Data::Dumper;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;
use File::Slurp              qw/write_file/;
use MIME::Base64             qw/encode_base64/;

use XML::LibXML;
use XML::Compile::WSS::Util  qw/:xtp10 :wsm10/;
use XML::Compile::WSS::SecToken::EncrKey ();

use_ok('XML::Compile::Cache');
use_ok('XML::Compile::WSS');
use_ok('XML::Compile::WSS::Signature');
use_ok('XML::Compile::WSS::SecToken');

my $certfn    = 't/20cert.pem';

# Also examples in https://issues.apache.org/jira/browse/CXF-2894
# See http://msdn.microsoft.com/en-us/library/vstudio/aa967562%28v=vs.90%29.aspx
# and http://www.w3.org/TR/xmlenc-core/

use_ok('XML::Compile::WSS::SecToken::X509v3');
my $x509     = XML::Compile::WSS::SecToken::X509v3->fromFile($certfn);
my $x509fp   = $x509->fingerprint;
ok(defined $x509fp, 'got fingerprint');
my $x509fp64 = encode_base64 $x509fp;

my $token_xml = <<__TOKEN__;
<?xml version="1.0"?>
<xenc:EncryptedKey
   xmlns:xenc="http://www.w3.org/2001/04/xmlenc#" Id="EK"
   xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
  <xenc:EncryptionMethod
     Algorithm="http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"/>
  <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
    <wsse:SecurityTokenReference>
      <wsse:KeyIdentifier
         EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary"
         ValueType="http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#ThumbprintSHA1">$x509fp64</wsse:KeyIdentifier>
    </wsse:SecurityTokenReference>
  </ds:KeyInfo>
  <xenc:CipherData>
    <xenc:CipherValue>
tOkmh0f6Ez2x6Uc9I7J6gPlZA0H02eWGFmLrRxaIeZe15g/j7/NvRfpy09OnsiWyhmzbq16TNX/l
OAsRQD/K7VZb4MjTXBq6GWpK7ZF7k39VggqagzXLp8fu+V3bBcMtbZwspBIZggGwxJuKGONDu5w2
kIqm3CEd+mKr01G7IuE=
    </xenc:CipherValue>
  </xenc:CipherData>
</xenc:EncryptedKey>
__TOKEN__

my $schema    = XML::Compile::Cache->new;
ok(defined $schema);

my $wss       = XML::Compile::WSS::Signature->new
  ( version => '1.1'
  , schema  => $schema
  , prepare => 'NONE'
  , token   => 'dummy'
  );
isa_ok($wss, 'XML::Compile::WSS');
isa_ok($wss, 'XML::Compile::WSS::Signature');

write_file 'dump/encrkey/template'
  , $wss->schema->template(PERL => 'xenc:EncryptedKey');

my $data      = $wss->schema
  ->reader('xenc:EncryptedKey')
  ->($token_xml);

write_file 'dump/encrkey/read.dd', Dumper $data;

$wss->keyInfo->addToken($x509);

my $sec1 = {};
my $encr = XML::Compile::WSS::SecToken::EncrKey
  ->getEncrypter($wss)->($data, $sec1);

ok(defined $encr, 'read encrypter');

isa_ok($encr, 'XML::Compile::WSS::SecToken::EncrKey');
is($encr->id, 'EK');

# Check reuse of object.
my $encr2 = XML::Compile::WSS::SecToken::EncrKey
  ->getEncrypter($wss)->($data, $sec1);
ok(defined $encr2);
is($encr, $encr2, 'reuse encryped object');

# Now get the key
my $getkey = XML::Compile::WSS::SecToken::EncrKey->getKey($wss);
is(ref $getkey, 'CODE', 'key producer');

my $key = $getkey->($data, $sec1);
ok(defined $key, 'got key');

done_testing;
