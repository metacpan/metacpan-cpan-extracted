use Test::More tests => 5;

use XML::Parser::Lite::Tree;


#
# test processing instructions
#

my $parser = new XML::Parser::Lite::Tree(skip_white => 1);
my $tree = $parser->parse(q~
	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
		"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
	<foo>
		<bar />
	</foo>
~);

is(&get_node($tree, '0'  )->{type}, 'dtd');
is(&get_node($tree, '1'  )->{type}, 'element');
is(&get_node($tree, '1/0')->{type}, 'element');

is(&get_node($tree, '0'  )->{name}, 'html');
like(&get_node($tree, '0')->{content}, qr/^PUBLIC/);


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
