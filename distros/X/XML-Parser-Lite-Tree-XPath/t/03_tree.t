use Test::More tests => 8;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Tokener;
use XML::Parser::Lite::Tree::XPath::Tree;


# NodeType arg sets
test_tree("processing-instruction()");
test_tree("processing-instruction('foo')");
test_tree("processing-instruction(1)", 1);
test_tree("processing-instruction('foo' 'bar')", 1);
test_tree("processing-instruction 'foo'");
test_tree("text()");
test_tree("text(1)", 1);
test_tree("text 'foo'");


#use Data::Dumper;
#print Dumper test_tree('/foo/bar/baz');


sub test_tree {
	my ($path, $fail_tree) = @_;
	my $tokener = XML::Parser::Lite::Tree::XPath::Tokener->new();
	if (!$tokener->parse($path)){
		ok(0);
		return;
	}
	my $tree = XML::Parser::Lite::Tree::XPath::Tree->new();
	if ($fail_tree){
		ok(!$tree->build_tree($tokener->{tokens}));
	}else{
		ok($tree->build_tree($tokener->{tokens}));
	}
	return $tree;
}
