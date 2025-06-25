#!/usr/bin/env perl
# This code is part of distribution XML-Compile-WSS-Signature.
# Meta-POD processed with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

# Check processing of SignedInfo

use warnings;
use strict;

use lib '../XML-Compile-WSS/lib', 'lib';

use Log::Report mode => 2;
use Test::More  tests => 11;

use Data::Dumper;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys  = 1;

use File::Slurp              qw/write_file/;
use MIME::Base64             qw/encode_base64/;

use XML::LibXML              ();
use XML::Compile::WSS::Util  qw/:dsig/;
use XML::Compile::C14N::Util qw/C14N_EXC_NO_COMM/;
use XML::Compile::Tester     qw/compare_xml/;

sub newdoc() { XML::LibXML::Document->new('1.0', 'UTF8') }

use_ok('XML::Compile::Cache');
use_ok('XML::Compile::WSS::SignedInfo');
use_ok('XML::Compile::WSS::Signature');

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

### save template

write_file 'dump/signedinfo/template'
  , $wss->schema->template(PERL => 'ds:SignedInfo');

write_file 'dump/signedinfo/InclusiveNamespaces.templ'
  , $wss->schema->template(PERL => 'c14n:InclusiveNamespaces');

### top-level SignedInfo readers and writers

my $si     = XML::Compile::WSS::SignedInfo->new;
isa_ok($si, 'XML::Compile::WSS::SignedInfo');

### Digest

my $canon1 = $si->_get_canonic(C14N_EXC_NO_COMM, [ qw/wsse SOAP-ENV/ ]);
my $dig1   = $si->_get_digester(DSIG_SHA1, $canon1);
my $ex1    = <<__EXAMPLE1;
<wsu:top
   xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
      <wsu:Timestamp wsu:Id="TS-1">
        <wsu:Created>2013-03-07T17:11:17.451Z</wsu:Created>
        <wsu:Expires>2013-03-07T17:16:17.451Z</wsu:Expires>
      </wsu:Timestamp>
</wsu:top>
__EXAMPLE1
my ($ts1) = $schema->dataToXML($ex1)->getElementsByLocalName('Timestamp');
#warn $ts1->toString(1);

# XXX MO: this differs from the example!  However, that is probably reformatted.
is(encode_base64($dig1->($ts1)), "gfjDZY969s7O4c0xhK7FxiXN7JM=\n");

### SignedInfo

my $b2   = $si->builder($wss);
isa_ok($b2, 'CODE', 'signedinfo builder');

my $doc2 = newdoc;
my ($info2, $canon2) = $b2->($doc2, [$ts1], DSIG_HMAC_SHA1);
isa_ok($info2, 'XML::LibXML::Element');

is($info2->toString(1)."\n", <<'__EXPECT');
<ds:SignedInfo xmlns:c14n="http://www.w3.org/2001/10/xml-exc-c14n#" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#">
    <c14n:InclusiveNamespaces PrefixList="SOAP-ENV"/>
  </ds:CanonicalizationMethod>
  <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#hmac-sha1"/>
  <ds:Reference URI="#TS-1">
    <ds:Transforms>
      <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#">
        <c14n:InclusiveNamespaces PrefixList="SOAP-ENV"/>
      </ds:Transform>
    </ds:Transforms>
    <ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
    <ds:DigestValue>tUsn5vQc0RxHgy8u/btX3fHZAsA=</ds:DigestValue>
  </ds:Reference>
</ds:SignedInfo>
__EXPECT
