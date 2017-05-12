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

my $style = <<'EOT';
<%
	$t->{foo}{testcode} = sub{ return 'bar'; }
%><%= apply_templates() %>
EOT

test_xml( '<doc><foo><bar /><blah /></foo></doc>', 
		$style, 
		"<doc><bar></bar></doc>\n", 
		'testcode returning xpath' );
