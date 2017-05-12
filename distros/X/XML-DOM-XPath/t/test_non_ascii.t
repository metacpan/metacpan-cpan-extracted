#!/usr/bin/perl -w
use strict;

# $Id: test_non_ascii.t,v 1.2 2005/10/18 08:37:22 mrodrigu Exp $


use Test::More tests => 10;
use XML::DOM::XPath;

use encoding 'utf8';

my $display_warning=0;

{ 
  my $dom = XML::DOM::Parser->new();
  my $doc = $dom->parsefile( "t/non_ascii.xml");
  if( !$doc->toString eq "<doc><ent>aü</ent><char>bü</char></doc>\n") { $display_warning=1; }
  is( $doc->toString, "<doc><ent>aü</ent><char>bü</char></doc>\n",'toString (on file)');
  is( $doc->findvalue( '//char'), "bü", "findvalue( '//char') (on file)");
  is( $doc->findnodes_as_string( '//char'), '<char>bü</char>', "findnodes_as_string( '//char') (on file)");
  is( $doc->findvalue( '//ent'), 'aü', "findvalue( '//ent') (on file)");
  is( $doc->findnodes_as_string( '//ent'), '<ent>aü</ent>', "findnodes_as_string( '//ent') (on file)");
}


{ 
  my $xmlStr = q{<doc><ent>a&#252;</ent><char>bü</char></doc>};
  my $dom = XML::DOM::Parser->new();
  my $doc = $dom->parse($xmlStr);
  is( $doc->toString, qq{<doc><ent>aü</ent><char>bü</char></doc>\n},'toString (on string)');
  is( $doc->findvalue( '//char'), 'bü', "findvalue( '//char') (on string)");
  is( $doc->findnodes_as_string( '//char'), qq{<char>bü</char>}, "findnodes_as_string( '//char') (on string)");
  is( $doc->findvalue( '//ent'), qq{aü}, "findvalue( '//ent') (on string)");
  is( $doc->findnodes_as_string( '//ent'), qq{<ent>aü</ent>}, "findnodes_as_string( '//ent') (on string)");
}

if( $display_warning)
  { warn "One possible reason why this test might fail is if XML::Parser and XML::DOM were\n",
         "installed with a different version of perl, compiled with a different set of options.\n",
         "For example upgrading Ubuntu from Dapper Drake to Edgy Eft will cause this test to fail.\n",
         "Re-installing XML::Parser and XML::DOM will fix the problem.\n"
         ;
  }
