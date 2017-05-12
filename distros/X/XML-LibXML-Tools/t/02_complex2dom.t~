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

{ # just one node
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root></root>\n|;
  my $dom = $tool->complex2Dom( data => [ "root" => "" ] );
  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'just one node')|| diag("$str_res ne $XMLCHK");
}

{ # lots of nodes
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root><page>data</page><test>more</test><tests>5</tests></root>\n|;
  my $dom = $tool->complex2Dom( data => [ root => [ page => "data",
						    test => "more",
						    tests => 5,
						  ] ] );
  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'lots of nodes')|| diag("$str_res ne $XMLCHK");
}

{ # nested nodes
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root><page><page1>data</page1></page><page><page2>more data</page2></page></root>\n|;
  my $dom = $tool->complex2Dom( data => [ root => [ page => [ page1 => "data" ],
						    page => [ page2 => "more data" ],
						  ] ] );
  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'nested nodes')|| diag("$str_res ne $XMLCHK");
}

{ # nodes with attributes
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root><page attr="value">data</page><page>attribute less data</page></root>\n|;
  my $dom = $tool->complex2Dom( data => [ root => [ page => [ $tool->attribute("attr", "value"),
							      "data" ],
						    page => "attribute less data",
						  ]
					] );
  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'nodes with attributes')|| diag("$str_res ne $XMLCHK");
}

{ # nodes and comments
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root><page>data</page><!-- Commentaar? --></root>\n|;
  my $dom = $tool->complex2Dom( data => [ root => [ page => "data",
						    $tool->comment("Commentaar?"),
						  ] ] );
  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'nodes and comments')|| diag("$str_res ne $XMLCHK");
}

