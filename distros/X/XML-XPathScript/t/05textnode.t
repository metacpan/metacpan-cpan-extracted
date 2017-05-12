use strict;
use Test;

BEGIN { 
	plan tests => 2, todo => [];
}

use XML::XPathScript;

sub test_xml {
	my( $xml, $style, $result, $comment ) = @_;
    my $xps = new XML::XPathScript( xml => $xml, stylesheet => $style );
	my $buffer;
	$xps->process( \$buffer );

	ok( $buffer, $result, $comment );
}

test_xml( '<doc>dummy</doc>', <<'STYLESHEET', "<doc>replaced</doc>\n", 'string replacement' );
<%
	$t->{'#text'}{pre}  = 'repla';
	$t->{'#text'}{post} = 'ced';
%><%= apply_templates() %>
STYLESHEET

test_xml( '<doc>dummy</doc>', <<'STYLESHEET', "<doc><txt>dummy</txt></doc>\n", 'string replacement with DO_TEXT_AS_CHILD' );
<%
	$t->{'#text'}{pre}  = '<txt>';
	$t->{'#text'}{post} = '</txt>';
	$t->{'#text'}{testcode} = sub { DO_TEXT_AS_CHILD };
%><%= apply_templates() %>
STYLESHEET
