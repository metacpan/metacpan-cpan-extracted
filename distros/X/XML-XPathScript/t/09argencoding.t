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

my $xml = '<foo bar="guts &amp; &lt;\'thunder\'&gt;"></foo>';
test_xml( $xml,  '<%= apply_templates %>', $xml, 'attribute escaping' );

$xml = "<foo bar='guts &amp; \"thunder\"'></foo>";
test_xml( $xml,  '<%= apply_templates %>', 
	'<foo bar="guts &amp; &quot;thunder&quot;"></foo>', 'attribute escaping' );
