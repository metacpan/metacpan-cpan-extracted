use Test::More tests => 4;

use XML::Parser::Lite::Tree;
my $x = XML::Parser::Lite::Tree->instance();

my $tree = $x->parse('<foo><![CDATA[MethodUndefined]]></foo>');

is(&get_node($tree, '0')->{type}, 'element');
is(&get_node($tree, '0')->{name}, 'foo');

is(&get_node($tree, '0/0')->{type}, 'cdata');
is(&get_node($tree, '0/0')->{content}, 'MethodUndefined');






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

