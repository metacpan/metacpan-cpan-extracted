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
<%	my $inc = XML::XPathScript::current->document( './t/document_file.txt' ) %>
<%= $inc->findvalue( './text()') %>
EOT

test_xml( '<dummy/>', 	$style,	"\ndocument() works!\n", 'document())' );

