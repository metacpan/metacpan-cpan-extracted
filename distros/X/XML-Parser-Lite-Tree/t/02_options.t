use Test::More tests => 36;

use XML::Parser::Lite::Tree;


#
# test the whitespace folding
#

my $parser = new XML::Parser::Lite::Tree(skip_white => 1);
my $tree = $parser->parse("<foo>  <bar> <baz>woo</baz></bar>  </foo>");

is(scalar @{&get_node($tree, ''     )->{children}}, 1, "one child of the root node");
is(scalar @{&get_node($tree, '0'    )->{children}}, 1, "one child, level 2");
is(scalar @{&get_node($tree, '0/0'  )->{children}}, 1, "one child, level 3");
is(scalar @{&get_node($tree, '0/0/0')->{children}}, 1, "one child, level 4");

is(&get_node($tree, '0'      )->{type}, 'element');
is(&get_node($tree, '0/0'    )->{type}, 'element');
is(&get_node($tree, '0/0/0'  )->{type}, 'element');
is(&get_node($tree, '0/0/0/0')->{type}, 'text');

is(&get_node($tree, '0'      )->{name}, 'foo');
is(&get_node($tree, '0/0'    )->{name}, 'bar');
is(&get_node($tree, '0/0/0'  )->{name}, 'baz');
is(&get_node($tree, '0/0/0/0')->{content}, 'woo');


#
# test the namespace parsing
#

my $xml = q~
	<aaa
		xmlns="urn:default"
		xmlns:foo="urn:foo"
	>
		<bbb />
		<foo:ccc
			xmlns="urn:override"
		>
			<ddd xmlns:bar="urn:bar" />
		</foo:ccc>
	</aaa>
~;

$parser = new XML::Parser::Lite::Tree(process_ns => 1, skip_white => 1);
$tree = $parser->parse($xml);

is(&get_node($tree, '0'    )->{ns}, 'urn:default');
is(&get_node($tree, '0/0'  )->{ns}, 'urn:default');
is(&get_node($tree, '0/1'  )->{ns}, 'urn:foo');
is(&get_node($tree, '0/1/0')->{ns}, 'urn:override');

is(&get_node($tree, '0'    )->{name}, 'aaa');
is(&get_node($tree, '0/0'  )->{name}, 'bbb');
is(&get_node($tree, '0/1'  )->{name}, 'foo:ccc');
is(&get_node($tree, '0/1/0')->{name}, 'ddd');

is(&get_node($tree, '0'    )->{local_name}, 'aaa');
is(&get_node($tree, '0/0'  )->{local_name}, 'bbb');
is(&get_node($tree, '0/1'  )->{local_name}, 'ccc');
is(&get_node($tree, '0/1/0')->{local_name}, 'ddd');

is(&get_node($tree, '0'    )->{namespaces}->{__default__}, 'urn:default');
is(&get_node($tree, '0/0'  )->{namespaces}->{__default__}, 'urn:default');
is(&get_node($tree, '0/1'  )->{namespaces}->{__default__}, 'urn:override');
is(&get_node($tree, '0/1/0')->{namespaces}->{__default__}, 'urn:override');

is(&get_node($tree, '0'    )->{namespaces}->{foo}, 'urn:foo');
is(&get_node($tree, '0/0'  )->{namespaces}->{foo}, 'urn:foo');
is(&get_node($tree, '0/1'  )->{namespaces}->{foo}, 'urn:foo');
is(&get_node($tree, '0/1/0')->{namespaces}->{foo}, 'urn:foo');

is(&get_node($tree, '0    ')->{namespaces}->{bar}, undef);
is(&get_node($tree, '0/0  ')->{namespaces}->{bar}, undef);
is(&get_node($tree, '0/1  ')->{namespaces}->{bar}, undef);
is(&get_node($tree, '0/1/0')->{namespaces}->{bar}, 'urn:bar');




#
# a super-simple xpath-like function for finding a single given child
#

sub get_node {
	my ($tree, $path) = @_;
	my $node = $tree;
	if (length $path){
		my @refs = split /\//, $path;
		for my $ref (@refs){
			$node = $node->{children}->[$ref];
		}
	}
	return $node;
}
