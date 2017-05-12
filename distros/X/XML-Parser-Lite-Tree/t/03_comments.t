use Test::More tests => 9;

use XML::Parser::Lite::Tree;


#
# test comment nodes
#

my $parser = new XML::Parser::Lite::Tree(skip_white => 1);
my $tree = $parser->parse(q~
	<foo>
		<woo />
		<!-- yay -->
		<hoopla />
	</foo>
~);

is(&get_node($tree, '0'  )->{type}, 'element');
is(&get_node($tree, '0/0')->{type}, 'element');
is(&get_node($tree, '0/1')->{type}, 'comment');
is(&get_node($tree, '0/2')->{type}, 'element');

is(&get_node($tree, '0'  )->{name}, 'foo');
is(&get_node($tree, '0/0')->{name}, 'woo');
is(&get_node($tree, '0/1')->{name}, undef);
is(&get_node($tree, '0/2')->{name}, 'hoopla');

is(&get_node($tree, '0/1')->{content}, ' yay ');



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
