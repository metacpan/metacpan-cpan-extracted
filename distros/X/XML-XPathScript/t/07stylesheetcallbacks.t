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

my $style = <<'EOT';
<%
	$t->{doc}{testcode} = sub{
       my ($self, $t) = @_;
       my ($blahnode) = findnodes(".//blah", $self);
       $t->{pre} = findvalue('@value', $blahnode);
       return DO_SELF_ONLY;
    }
%><%= apply_templates() %>
EOT

test_xml( '<doc><foo><bar /><blah value="ok"/></foo></doc>', 
		$style, 
		"ok\n", 
		'findnodes($node,$path) and findvalue($node)' );

$style = <<'EOT';
<%
	$t->{doc}{testcode} = sub{
       my ($self, $t) = @_;
       my ($blahnode) = findnodes("/doc/foo/blah", $self);
       $t->{pre} = findvalue('@value', $blahnode);
       return DO_SELF_ONLY;
    }
%><%= apply_templates() %>
EOT

test_xml( '<doc><foo><bar /><blah value="ok"/></foo></doc>', 
		$style, 
		"ok\n", 
		'findnodes($node) - absolute XPath search' );

1;
