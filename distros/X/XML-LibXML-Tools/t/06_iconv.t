#!/usr/local/bin/perl -Tw

BEGIN {
  use lib "../../../../../lib-perl";
}

# use Test::More tests => 5;
use Test::More skip_all => "No longer supports conversion";
use strict;

use XML::LibXML::Tools;
$XML::LibXML::Tools::croak = 0;

{ # bogus encodings - we should survive this.
  my $tool = XML::LibXML::Tools->new( encoding => "FOO-8859-1",
				      toEncoding => "shit_jis",
				    );
  like( $tool, qr/XML::LibXML::Tools/, "Object with bogus encoding" )
    || diag("Object creation does not survive bogus encodings");

  my $iconv = $tool->getConverter;
  is($iconv, "", "Has no converter")
    || diag("Object has converter, even with bogus encoding");

  my $XMLCHK = qq|<?xml version="1.0" encoding="UTF-8"?>\n<root><enc>1 eë</enc></root>\n|;
  my $dom = $tool->complex2Dom( data => [ root => [ enc => "1 eë" ] ] );
  $dom->setEncoding("UTF-8");

  my $str_res = $dom->toString(0);
  is($str_res, $XMLCHK, 'Can still make utf-8 XML') || diag("$str_res ne $XMLCHK" );
}

{ # good encodings - this sould provide iconv
  my $tool = XML::LibXML::Tools->new( encoding => "ISO-8859-1",
				      toEncoding => "UTF-8",
				    );
  like( $tool, qr/XML::LibXML::Tools/, "Object with good encoding" );

  my $iconv = $tool->getConverter;
  isnt($iconv, "", "Has converter");
}
