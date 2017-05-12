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

my $xml = '<doc><foo/></doc>';
my $stylesheet = <<'END_STYLESHEET';
<%
$t->set( 'foo', { pre => 'bar' } );
$t->set( 'baz', { post => 'blargh' } );

%>
<%= apply_templates %>
END_STYLESHEET


test_xml( $xml,  $stylesheet, "\n<doc>bar</doc>\n", 'set()' );


{
    my $xps = new XML::XPathScript( xml => $xml, 
                                    stylesheet => <<'END_STYLESHEET' );
<% $t->set( 'foo', { pre => 'bar' } ); %>
<%= $t->dump() %>
END_STYLESHEET

    my $buffer;
    $xps->process( \$buffer );

    my $template;
    eval $buffer;

    ok( $template->{foo}{pre}, 'bar', 'dump()' );

}

