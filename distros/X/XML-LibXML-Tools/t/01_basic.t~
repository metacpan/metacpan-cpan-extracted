#!/usr/local/bin/perl -Tw

use Test::More tests => 6;
use strict;
use Data::Dumper;

#
# test use
#
BEGIN{
  use lib "../../../../../lib-perl";
  use_ok('XML::LibXML::Tools');
}
$XML::LibXML::Tools::croak = 0;

#
# object creation
#
my $tool = XML::LibXML::Tools->new();
like($tool, qr/XML::LibXML::Tools/, "object creation")
  || diag("$tool is not the right object");

# check croak
is ( $tool->croakOnError, 0, 'croakOnError listens to $croak' );

{ # creation
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root><page1>1</page1><page2>2</page2></root>\n|;
  my $dom = $tool->complex2Dom( data => [ root => [ page1 => 1,
						    page2 => 2 ] ] );
  my $str_res = $dom->toString(0);
  is($str_res, $XMLCHK, 'complex2Dom') || diag("$str_res ne $XMLCHK" );
}


{ # test attribute
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root wow="ok"><page/></root>\n|;
  my $dom = $tool->complex2Dom( data =>
				[ root =>
				  [ $tool->attribute("wow" => "ok"),
				    'page'=> [] ] ] );

  my $str_res = $dom->toString(0);
  is($str_res, $XMLCHK, 'attribute') || diag("$str_res ne $XMLCHK" );
}

{ # test comment
  my $XMLCHK = qq|<?xml version="1.0"?>\n<root><!-- foo bar --><page/></root>\n|;
  my $dom = $tool->complex2Dom( data =>
				[ root =>
				  [ $tool->comment("foo bar"),
				    'page'=> [] ]
				] );

  my $str_res = $dom->toString(0);
  is($str_res, $XMLCHK, 'test comment')|| diag("$str_res ne $XMLCHK" );
}


