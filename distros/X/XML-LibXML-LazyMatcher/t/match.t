#-*- perl -*-

use strict;
use warnings;
use Test::More tests => 15;

use XML::LibXML;

use_ok ("XML::LibXML::LazyMatcher");

{
    my $matcher;
    {
	my $dom = XML::LibXML->load_xml (string => "<root><c1><c2>content</c2></c1></root>");
	ok ($dom, "dom");

	{
	    package XML::LibXML::LazyMatcher;
	    $matcher = M (root =>
			  C (M (c1 =>
				C (M (c2 =>
				      sub {
					  $_[0]->textContent eq "content";
				      })))));
	}
	ok ($matcher->($dom->documentElement), "matcher");
    }

    {
	my $dom = XML::LibXML->load_xml (string => "<root><c1><c3>content</c3></c1></root>");
	ok (! $matcher->($dom->documentElement), "failure");
    }

    {
	my $dom = XML::LibXML->load_xml (string => "<root><c1><c3>different content</c3></c1></root>");
	ok (! $matcher->($dom->documentElement), "failure");
    }
}

{
    my $dom = XML::LibXML->load_xml (string => "<root><c1><c2>hello</c2><c3>world</c3></c1></root>");
    my $matcher;
    my ($c2content, $c3content);
    {
	package XML::LibXML::LazyMatcher;
	$matcher = M (root =>
		      C (M (c1 =>
			    C (M (c2 =>
				  sub {
				      $c2content = $_[0]->textContent;
				      return 1;
				  }),
			       M (c3 =>
				  sub {
				      $c3content = $_[0]->textContent;
				      return 1;
				  })))));
    }
    ok ($matcher->($dom->documentElement), "children");
    ok ($c2content eq "hello", "content");
    ok ($c3content eq "world", "content");
}

{
    my $dom = XML::LibXML->load_xml (string => "<root><c1 key='1'/><c1 key='2'/></root>");
    my $flag = [];
    my $order = [];
    my $matcher;
    {
	package XML::LibXML::LazyMatcher;
	$matcher = M (root =>
		      C (M (c1 =>
			    sub {
				my $k = $_[0]->getAttribute ("key");
				$flag->[$k] = 1;
				push @$order, $k;
			    })));
    }
    ok ($matcher->($dom->documentElement), "repeating");
    ok (!$flag->[0], "content");
    ok ($flag->[1], "content");
    ok ($flag->[2], "content");
    ok (!$flag->[3], "content");
    ok ($order->[0] = 1, "order");
    ok ($order->[1] = 2, "order");
}
