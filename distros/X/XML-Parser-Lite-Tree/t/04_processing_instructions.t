use Test::More tests => 9;

use XML::Parser::Lite::Tree;


#
# test processing instructions
#

my $parser = new XML::Parser::Lite::Tree(skip_white => 1);
my $tree = $parser->parse(q~
	<?xml version="1.0" encoding="utf-8"?>
	<foo>
		<woo />
		<hoopla />
		<?php echo 'Hello world'; ?>
	</foo>
~);

is(&get_node($tree, '0'  )->{type}, 'pi');
is(&get_node($tree, '1'  )->{type}, 'element');
is(&get_node($tree, '1/0')->{type}, 'element');
is(&get_node($tree, '1/1')->{type}, 'element');
is(&get_node($tree, '1/2')->{type}, 'pi');

is(&get_node($tree, '0'  )->{target}, 'xml');
is(&get_node($tree, '1/2')->{target}, 'php');

like(&get_node($tree, '0'  )->{content}, qr/^version/);
like(&get_node($tree, '1/2')->{content}, qr/^echo/);





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
