use strict;
use Test;

BEGIN { 
	plan tests => 1, todo => [];
}

use XML::XPathScript;

sub test_xml {
	my( $xml, $style, $result, $comment ) = @_;
    my $xps = new XML::XPathScript( xml => $xml, stylesheet => $style );
	my $buffer;
	$xps->process( \$buffer );

	ok( $buffer, $result, $comment );
}

my $xml = '<doc></doc>';
test_xml( $xml,  '<%= apply_templates %><%# print "Hello!"; %>', $xml, '<%# comments %>' );

