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

{ # adding after
  my $dom = $tool->complex2Dom( data => [ root => [ page1 => 1 ] ] );

  my $XMLCHK = qq|<?xml version="1.0"?>\n<root><page1>1</page1><page2>1</page2></root>\n|;
  $tool->domAdd(dom      => $dom,
		location => AFTER,
		xpath    => "/root/page1",
		data     => [ page2 => 1 ] );

  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'array ATFER') || diag("$str_res ne $XMLCHK");
}

{ # trying to add after the root
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root><page1>1</page1></root>\n|;
  my $dom = $tool->complex2Dom( data => [ root => [ page1 => 1 ] ] );

  $tool->domAdd(dom      => $dom,
		location => AFTER,
		xpath    => "/root",
		data     => [ page2 => 2 ] );

  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'array - AFTER ROOT')
    || diag("$str_res ne $XMLCHK");
  isnt($tool->errorMsg, "", "Should give error")
    || diag("Succesfully added before or after the root element - ERROR!");
}

{ # add a nodeset
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root><page1>1<root><page1>1</page1><page2>2</page2></root></page1><page2>2</page2></root>\n|;
  my $dom = $tool->complex2Dom(data => [ root => [ page1 => "1",
						   page2 => "2" ] ]);
  $tool->domAdd(dom => $dom,
		xpath => "/root/page1",
		data => [ $dom->findnodes("/root") ] );

  my $str_res = $dom->toString(0);
  is($str_res, $XMLCHK, 'nodeset') || diag("str_res ne $XMLCHK");
}

{ # an element.
  my $XMLCHK = qq|<?xml version="1.0"?>
<root><page>data</page><page>data</page></root>
|;

  my $dom = $tool->complex2Dom(data => [ root => [ page => "data" ] ]);
  $tool->domAdd(dom => $dom,
		xpath => "/root/page",
		location => AFTER,
		data => [ $dom->documentElement->firstChild ]);
  my $str_res = $dom->toString(0);

  is($str_res, $XMLCHK, 'domAdd own rootElement on rootElement') || diag("$str_res ne $XMLCHK");
}
