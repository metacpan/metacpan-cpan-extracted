use Tree::Nary;

use strict;

sub test() {

	my $root;
	my $node;
	my $i;

	$root = Tree::Nary->new();
	$node = $root;

	for($i = 0; $i < 2048; $i++) {

		Tree::Nary->append($node, Tree::Nary->new());

		if(($i%5) == 4) {
			$node = $node->{children}->{next};
		}
	}

	print "not " if(Tree::Nary->max_height($root) <= 100);
	print "ok 1\n";

	print "not " if(Tree::Nary->n_nodes($root, $Tree::Nary::TRAVERSE_ALL) != 1 + 2048);
	print "ok 2\n";

	# Tree::Nary->DESTROY($root);

}

print "1..2\n";

&test();
