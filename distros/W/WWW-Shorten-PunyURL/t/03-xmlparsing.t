#!perl -T

use utf8;

use Test::More tests => 4;

use WWW::Shorten::PunyURL;
use XML::LibXML::XPathContext;

my $url = 'http://developers.sapo.pt/';
my $punyurl = WWW::Shorten::PunyURL->new(
    url => $url
);

my $xml =<<__EOXML__;
<?xml version="1.0" encoding="utf-8"?>
<punyURL xmlns="http://services.sapo.pt/Metadata/PunyURL">
  <puny>http://漭.sl.pt</puny>
  <ascii>http://b.ot.sl.pt</ascii>
  <preview>http://b.ot.sl.pt/-</preview>
  <url><![CDATA[http://developers.sapo.pt/]]></url>
</punyURL>
__EOXML__

my $doc = $punyurl->parser->parse_string( $xml );
my $xpc = XML::LibXML::XPathContext->new( $doc );
$xpc->registerNs( 'p', 'http://services.sapo.pt/Metadata/PunyURL' );

my $puny     = $xpc->findvalue( '//p:puny' );
my $ascii    = $xpc->findvalue( '//p:ascii' );
my $preview  = $xpc->findvalue( '//p:preview' );
my $original = $xpc->findvalue( '//p:url' );

$punyurl->puny( $puny );
$punyurl->ascii( $ascii );
$punyurl->original( $original );
$punyurl->preview( $preview );

is( $punyurl->puny, 'http://漭.sl.pt', 'PunyURL (Unicode) found' );
is( $punyurl->ascii, 'http://b.ot.sl.pt', 'PunyURL (ASCII) found' );
is( $punyurl->preview, 'http://b.ot.sl.pt/-', 'PunyURL (Preview) found' );
is( $punyurl->original, 'http://developers.sapo.pt/', 'Original URL found' );