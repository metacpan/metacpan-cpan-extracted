#!/usr/local/bin/perl -Tw

BEGIN {
  use lib "../../../../../lib-perl";
}

use Test::More tests => 11;
use strict;
use Data::Dumper;
use XML::LibXML::Tools;
$XML::LibXML::Tools::croak = 0;

my $tool = XML::LibXML::Tools->new( croakOnError => 0);


#
# array based playfield
#

{ my $XMLCHK = qq|<?xml version="1.0"?>\n<root><page>new data</page></root>\n|;
  my $dom = $tool->complex2Dom( data => [ root => [ page => "data" ] ] );
  $tool->domUpdate(dom => $dom,
		   xpath => "/root",
		   data => [ page => "new data" ] );

  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'array default')|| diag("$str_res ne $XMLCHK");
}

{ # add comment
  my $XMLCHK = qq{<?xml version="1.0"?>
<root><page attribute="value">data</page></root>
};
  my $dom = $tool->complex2Dom( data => [ root => [ page => "data" ] ] );
  $tool->domUpdate( dom => $dom,
		    xpath => "/root/page",
		    data => [ $tool->attribute("attribute", "value") ] );
  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'adding attribute') || diag("str_res ne $XMLCHK");
}

{ # update attribute
  my $XMLCHK = qq{<?xml version="1.0"?>
<root><page atrib="new value">data</page></root>
};
  my $dom = $tool->complex2Dom( data => [ root => [ page => [ $tool->attribute("atrib", "value"),
							      "data" ] ] ] );
  $tool->domUpdate( dom => $dom,
		    xpath => "/root/page",
		    data => [ $tool->attribute("atrib", "new value") ] );
  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'update attribute') || diag("str_res ne $XMLCHK");
}

{ # comment
  my $XMLCHK = qq{<?xml version="1.0"?>
<root><page>data</page><!-- foo, bar --></root>
};
  my $dom = $tool->complex2Dom( data => [ root => [ page => "data" ] ] );
  $tool->domUpdate( dom => $dom,
		    xpath => "/root",
		    data => [ $tool->comment("foo, bar") ] );
  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'adding comment') || diag("$str_res ne $XMLCHK");
}

{ # comment + attribute
  my $XMLCHK = qq{<?xml version="1.0"?>
<root><page atrib="value">data<!-- foo, bar --></page></root>
};
  my $dom = $tool->complex2Dom( data => [ root => [ page => "data" ] ] );
  $tool->domUpdate( dom => $dom,
		    xpath => "/root/page",
		    data => [ $tool->attribute("atrib", "value"),
			      $tool->comment("foo, bar") ] );
  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'adding comment AND attribute') || diag("$str_res ne $XMLCHK");
}

{ # comment + attribute
  my $XMLCHK = qq{<?xml version="1.0"?>
<root><page atrib="new value">data<!-- foo, bar --></page></root>
};
  my $dom = $tool->complex2Dom( data => [ root => [ page => [ $tool->attribute("atrib", "value"),
							      "data" ] ] ] );
  $tool->domUpdate( dom => $dom,
		    xpath => "/root/page",
		    data => [ $tool->attribute("atrib", "new value"),
			      $tool->comment("foo, bar") ] );
  my $str_res = $dom->toString(0);
  ok($str_res eq $XMLCHK, 'adding comment, updating attribute') || diag("$str_res ne $XMLCHK");
}

#
# dom based playfield
#

my $addingDom = $tool->complex2Dom( data => [ this => [ node => "data",
							node => "more data",
							node => [ deeper_node => "deep data" ] ] ]);
# <this>
#   <node>data</node>
#   <node>more data</node>
#   <node>
#     <deeper_node>deep data</deeper_node>
#   </node>
# </this>

{ # add a node
  my $XMLCHK = qq{<?xml version="1.0"?>
<root><page><node>data</node></page></root>
};
  my $dom = $tool->complex2Dom(data => [ root => [ page => '' ] ]);
  $tool->domUpdate( dom => $dom,
		    xpath => "/root/page",
		    data => [ $addingDom->documentElement->firstChild ] );

  my $chk = $dom->toString(0);
  is($chk,$XMLCHK,"Add XML::LibXML::Node")||diag("$chk ne $XMLCHK");
}

{ # add a nodeset
  my $XMLCHK = qq{<?xml version="1.0"?>
<root><page><node>data</node><node>more data</node></page></root>
};
  my $dom = $tool->complex2Dom(data => [ root => [ page => '' ] ]);
  $tool->domUpdate( dom => $dom,
		    xpath => "/root/page",
		    data => [ $addingDom->findnodes("/this/node[1]"),
			      $addingDom->findnodes("/this/node[2]") ] );
  my $chk = $dom->toString(0);
  is($chk,$XMLCHK,"Add XML::LibXML::NodeList")||diag("$chk ne $XMLCHK");
}

{ # add a dom
  my $XMLCHK = qq{<?xml version="1.0"?>
<root><page>data</page><this><node>data</node><node>more data</node><node><deeper_node>deep data</deeper_node></node></this></root>
};
  my $dom = $tool->complex2Dom(data => [ root => [ page => 'data' ] ]);
  $tool->domUpdate( dom => $dom,
		    xpath => "/root",
		    data => [ $addingDom ] );
  my $chk = $dom->toString(0);
  is($chk, $XMLCHK,"Add XML::LibXML::DOM") || diag("$chk en $XMLCHK");
}

{ # add an array and a nodeset
  my $XMLCHK = qq{<?xml version="1.0"?>
<root><page><array>node</array><node><deeper_node>deep data</deeper_node></node></page></root>
};
  my $dom = $tool->complex2Dom(data => [ root => [ page => '' ] ]);
  $tool->domUpdate( dom => $dom,
		    xpath => "/root/page",
		    data => [ array => "node",
			      $addingDom->findnodes("/this/node[3]") ] );

  my $chk = $dom->toString(0);
  is($chk,$XMLCHK,"Add array, NodeList")||diag("$chk ne $XMLCHK");
}

{ # add it all
  my $XMLCHK = qq{<?xml version="1.0"?>
<root><page><array><node>data</node></array><node><node>data</node></node><nodelist><node>more data</node></nodelist><dom><this><node>data</node><node>more data</node><node><deeper_node>deep data</deeper_node></node></this></dom></page></root>
};
  my $dom = $tool->complex2Dom(data => [ root => [ page => '' ] ]);
  $tool->domUpdate( dom => $dom,
		    xpath => "/root/page",
		    data => [ array => [ node => "data" ],
			      node => [ $addingDom->getDocumentElement->firstChild ],
			      nodelist => [ $addingDom->findnodes("/this/node[2]") ],
			      dom => [ $addingDom ]
			    ] );
  my $chk = $dom->toString(0);
  is($chk,$XMLCHK,"Add array, node, nodelist, dom") || diag("$chk ne $XMLCHK");
}
