use strict;
use Test::More;
use XML::Struct::Writer;
use Encode;

my ($struct, $xml);

sub write_xml {
    my $str = ""; 
    my $args = ref $_[-1] ? pop : { xmldecl => 0 }; 
    my $writer = XML::Struct::Writer->new( to => \$str, %$args );
    $writer->write(@_);
    $str;
}

$struct = { foo => [0], bar => [], doz => ["Hello","World"], x => undef };
$xml    = "<greet><bar/><doz>Hello</doz><doz>World</doz><foo>0</foo></greet>\n";
is write_xml($struct, "greet"), $xml, "simple format (with root)";

$struct = { foo => { bar => { doz => {} } } };
$xml    = "<root><foo><bar><doz/></bar></foo></root>\n";
is write_xml($struct, undef), $xml, "simple format (no root)";
is write_xml($struct, undef, { attributes => 0, xmldecl => 0 }), $xml, 
    "simple format (no root, no attributes)";

$struct = [ micro => {}, [ { xml => 1 } ] ];
$xml    = "<micro><xml>1</xml></micro>\n"; 
is write_xml($struct, undef), $xml, "mixed format (simple in micro)";

$struct = [ A => [ " ", { B => 1 }, "  ", { B => [] } ] ];
$xml    = "<A> <B>1</B>  <B/></A>\n";
is write_xml($struct, undef), $xml, "mixed format (simple in micro)";

$struct = { a => [ [ b => { a => 1 } ], [ c => { a => 1 }, ['d'] ] ] };
$xml    = "<root><a><b a=\"1\"/></a><a><c a=\"1\">d</c></a></root>\n";
is write_xml($struct, undef), $xml, "mixed format (micro in simple)";

$xml    = "<root><a><b/></a><a><c>d</c></a></root>\n";
is write_xml($struct, undef, { attributes => 0, xmldecl => 0 }), $xml, 
    "mixed format, no attributes";

done_testing;
