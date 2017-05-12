use Test::More;
use XML::LibXML 1.90;
use XML::LibXML::Devel::SetLineNumber;

my $xml = XML::LibXML->load_xml(string => <<'XML');
<foo>
	<bar>
		<baz />
	</bar>
</foo>
XML

my @nodes = $xml->getElementsByTagName('*');
plan tests => 2*@nodes;

for my $i (1 .. @nodes)
{
	is($nodes[$i-1]->line_number, 0, "BEFORE $i");
}

for my $i (1 .. @nodes)
{
	set_line_number($nodes[$i-1], $i);
}

for my $i (1 .. @nodes)
{
	is($nodes[$i-1]->line_number, $i, "AFTER $i");
}
