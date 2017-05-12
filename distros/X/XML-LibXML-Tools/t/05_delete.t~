#!/usr/local/bin/perl -Tw

BEGIN {
  use lib "../../../../../lib-perl";
}

use Test::More tests => 5;
use strict;
use Data::Dumper;
use XML::LibXML::Tools;
$XML::LibXML::Tools::croak = 0;

my $tool = XML::LibXML::Tools->new( croakOnError => 0);

{ # remove one node
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root/>\n|;
  my $dom = $tool->complex2Dom( data => [ root => [ page => "data" ] ] );
  $tool->domDelete( dom    => $dom, 
		    xpath  => "/root",
		    deleteXPath => "./page" );

  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'remove one node')|| diag("$str_res ne $XMLCHK");
}

{ # remove two nodes
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root/>\n|;
  my $dom = $tool->complex2Dom( data => [ root => [ page => "data",
						    page => "more data",
						  ] ] );
  $tool->domDelete( dom    => $dom,
		    xpath  => "/root",
		    deleteXPath => "./page" );

  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'remove two nodes')|| diag("$str_res ne $XMLCHK");
}

{ # remove middle node
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root><page>first data</page><page>last data</page></root>\n|;
  my $dom = $tool->complex2Dom( data => [ root => [ page => "first data",
						    page => "middle data",
						    page => "last data",
						  ] ] );
  $tool->domDelete( dom    => $dom,
		    xpath  => "/root",
		    deleteXPath => "./page[2]" );

  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'remove middle node')|| diag("$str_res ne $XMLCHK");

}

{ # remove last node using shorthand
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root><page>data</page><page>middle data</page></root>\n|;
  my $dom = $tool->complex2Dom( data => [ root => [ page => "data",
						    page => "middle data",
						    page => "last data",
						  ] ] );
  $tool->domDelete( dom    => $dom,
		    xpath  => "/root",
		    delete => "./page[3]" );

  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'remove last node using shorthand')|| diag("$str_res ne $XMLCHK");

}

{ # remove attribute
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root><page>data</page><page>more data</page></root>\n|;
  my $dom = $tool->complex2Dom( data => [ root =>
					  [ page => 
					    [ $tool->attribute("attr","value"),
					      "data" ],
					    page => "more data",
					  ] ] );
  $tool->domDelete( dom    => $dom,
		    xpath  => "/root",
		    delete => './page/@attr' );

  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'remove attribute')|| diag("$str_res ne $XMLCHK");
}

