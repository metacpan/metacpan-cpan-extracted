#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
  eval "use Test::XML::LibXML";
  if ($@) {
      Test::More::plan(
          skip_all => "Test::XML::LibXML required to test xml"
      );
  }
}


use Test::More tests => 3;

use XML::Easy::ProceduralWriter;
use Test::XML::LibXML;
  
{
  my $octlets = xml_bytes {
    element "flintstones", contains {
      element "family", surname => "flintstone", contains {
        element "person", hair => "black", contains {
          text "Fred";
        };
        element "person", hair => "blonde", contains {
      	  text "Wilma";
        };
        element "person", hair => "red", contains {
      	  text "Pebbles";
        };
      };
      element "family", surname => "rubble", contains {
        my %h = ("Barney" => "blonde", "Betty" => "black", "BamBam" => "white");
        foreach (qw( Barney Betty BamBam )) {
      	  element "person", hair => $h{$_}, contains { text $_ };
        }
      }
    };
  };

  test_xml($octlets, <<'XML', 'example from synopsis', { ignore_whitespace => 1 });
  <flintstones>
    <family surname="flintstone">
      <person hair="black">Fred</person>
      <person hair="blonde">Wilma</person>
      <person hair="red">Pebbles</person>
    </family>
    <family surname="rubble">
      <person hair="blonde">Barney</person>
      <person hair="black">Betty</person>
      <person hair="white">BamBam</person>
    </family>  
  </flintstones>
XML

}

########################################################################

{
  my $octlets = xml_bytes {
    element "rainbow", contains {
      text "rod,";
      text "jane,";
      text "freddy,";
      element "bold", contains { text "bungle," };
      text "george,";
      text "zippy"
    };
  };
  
  test_xml($octlets,"<rainbow>rod,jane,freddy,<bold>bungle,</bold>george,zippy</rainbow>",'multiple text');
}

########################################################################

# any args (this test makes less sense now element isn't an indirect method)
{
  my $octlets = xml_bytes {
    element "backend", contains {
      element "mark";
      my $chris = "chris"; element $chris;
      element "zef"."ram";
    };
  };
  
  test_xml($octlets,"<backend><mark/><chris/><zefram/></backend>");
}
