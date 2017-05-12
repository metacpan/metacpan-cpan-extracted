use Tree::Nary;
use strict;

sub node_build_string() {

	my ($node, $ref_of_arg) = (shift, shift);
	my $p = $ref_of_arg;
	my $string;
	my $c;

	$c = $node->{data};
	if(defined($p)) {
		$string = $$p;
	} else {
		$string = "";
	}

	$string .= $c;
	$$p = $string;
	
	return($Tree::Nary::FALSE);
}

sub test() {

	my $root = Tree::Nary->new("A");
	my $node = Tree::Nary->new();
	my $node_B = Tree::Nary->new("B");
	my $node_F = Tree::Nary->new("F");
	my $node_G = Tree::Nary->new("G");
	my $node_J = Tree::Nary->new("J");
	my $another_root = Tree::Nary->new("Z");

        my $returned_node;
	my $test;
	my $i;
	my $tstring;

	print "not " if(!(Tree::Nary->depth($root) == 1 && Tree::Nary->max_height($root) == 1));
	print "ok 1\n";

	$returned_node = Tree::Nary->append($root, $node_B);
	print "not " if($root->{children} != $node_B);
	print "ok 2\n";

	$returned_node = Tree::Nary->append_data($node_B, "E");
        print "not " if (!defined($returned_node) || ($returned_node->{'data'} ne 'E'));
	print "ok 3\n";

	$returned_node = Tree::Nary->prepend_data($node_B, "C");
        print "not " if (!defined($returned_node) || ($returned_node->{'data'} ne 'C'));
	print "ok 4\n";

	$returned_node = Tree::Nary->insert($node_B, 1, Tree::Nary->new("D"));
        print "not " if (!defined($returned_node) || ($returned_node->{'data'} ne 'D'));
	print "ok 5\n";

	$returned_node = Tree::Nary->append($root, $node_F);
        print "not " if (!defined($returned_node) || ($returned_node->{'data'} ne 'F'));
	print "ok 6\n";

	print "not " if($root->{children}->{next} != $node_F);
	print "ok 7\n";

	$returned_node = Tree::Nary->append($node_F, $node_G);
        print "not " if (!defined($returned_node) || ($returned_node->{'data'} ne 'G'));
	print "ok 8\n";

	$returned_node = Tree::Nary->prepend($node_G, $node_J);
        print "not " if (!defined($returned_node) || ($returned_node->{'data'} ne 'J'));
	print "ok 9\n";

	$returned_node = Tree::Nary->insert($node_G, 42, Tree::Nary->new("K"));
        print "not " if (!defined($returned_node) || ($returned_node->{'data'} ne 'K'));
	print "ok 10\n";

	$returned_node = Tree::Nary->insert_data($node_G, 0, "H");
        print "not " if (!defined($returned_node) || ($returned_node->{'data'} ne 'H'));
	print "ok 11\n";

	$returned_node = Tree::Nary->insert($node_G, 1, Tree::Nary->new("I"));
        print "not " if (!defined($returned_node) || ($returned_node->{'data'} ne 'I'));
	print "ok 12\n";

	print "not " if(Tree::Nary->depth($root) != 1);
	print "ok 13\n";

	print "not " if(Tree::Nary->max_height($root) != 4);
	print "ok 14\n";

	print "not " if(Tree::Nary->depth($node_G->{children}->{next}) != 4);
	print "ok 15\n";

	print "not " if(Tree::Nary->n_nodes($root, $Tree::Nary::TRAVERSE_LEAFS) != 7);
	print "ok 16\n";

	print "not " if(Tree::Nary->n_nodes($root, $Tree::Nary::TRAVERSE_NON_LEAFS) != 4);
	print "ok 17\n";

	print "not " if(Tree::Nary->n_nodes($root, $Tree::Nary::TRAVERSE_ALL) != 11);
	print "ok 18\n";

	print "not " if(Tree::Nary->max_height($node_F) != 3);
	print "ok 19\n";

	print "not " if(Tree::Nary->n_children($node_G) != 4);
	print "ok 20\n";

	# Find tests
	print "not " if(Tree::Nary->find_child($root, $Tree::Nary::TRAVERSE_ALL, "F") != $node_F);
	print "ok 21\n";

	print "not " if(defined(Tree::Nary->find($root, $Tree::Nary::LEVEL_ORDER, $Tree::Nary::TRAVERSE_NON_LEAFS, "I")));
	print "ok 22\n";

	print "not " if(Tree::Nary->find($root, $Tree::Nary::IN_ORDER, $Tree::Nary::TRAVERSE_LEAFS, "J") != $node_J);
	print "ok 23\n";

	for($i = 0; $i < Tree::Nary->n_children($node_B); $i++) {
		$node = Tree::Nary->nth_child($node_B, $i);
	}

	$test = $Tree::Nary::TRUE;
	for($i = 0; $i < Tree::Nary->n_children($node_G); $i++) {
		if(Tree::Nary->child_position($node_G, Tree::Nary->nth_child($node_G, $i)) == $i) {
			$test &= $Tree::Nary::TRUE;
		} else {
			$test &= $Tree::Nary::FALSE;
		}
	}

	if(!$test) {
		print "not ";
	}
	print "ok 24\n";

	#     We have built:                    A
	#                                     /   \
	#                                   B       F
	#                                 / | \       \
	#                               C   D   E       G
	#                                             / /\ \
	#                                           H  I  J  K
	#    
	#     For in-order traversal, 'G' is considered to be the "left" child
	#     of 'F', which will cause 'F' to be the last node visited.

	$tstring = undef;

	# Next test should be TRUE
	if(!Tree::Nary->is_ancestor($node_F, $node_G)) {
		print "not ";
	}
	print "ok 25\n";

	# Next test should be FALSE
	if(Tree::Nary->is_ancestor($node_G, $node_F)) {
		print "not ";
	}
	print "ok 26\n";

	Tree::Nary->traverse($root, $Tree::Nary::PRE_ORDER, $Tree::Nary::TRAVERSE_ALL, -1, \&node_build_string, \$tstring);

	print "not " if($tstring !~ /ABCDEFGHIJK/);
	print "ok 27\n";

	$tstring = undef;
	Tree::Nary->traverse($root, $Tree::Nary::POST_ORDER, $Tree::Nary::TRAVERSE_ALL, -1, \&node_build_string, \$tstring);

	print "not " if($tstring !~ /CDEBHIJKGFA/);
	print "ok 28\n";

	$tstring = undef;
	Tree::Nary->traverse($root, $Tree::Nary::IN_ORDER, $Tree::Nary::TRAVERSE_ALL, -1, \&node_build_string, \$tstring);

	print "not " if($tstring !~ /CBDEAHGIJKF/);
	print "ok 29\n";

	$tstring = undef;
	Tree::Nary->traverse($root, $Tree::Nary::LEVEL_ORDER, $Tree::Nary::TRAVERSE_ALL, -1, \&node_build_string, \$tstring);

	print "not " if($tstring !~ /ABFCDEGHIJK/);
	print "ok 30\n";

	$tstring = undef;
	Tree::Nary->traverse($root, $Tree::Nary::LEVEL_ORDER, $Tree::Nary::TRAVERSE_LEAFS, -1, \&node_build_string, \$tstring);

	print "not " if($tstring !~ /CDEHIJK/);
	print "ok 31\n";

	$tstring = undef;
	Tree::Nary->traverse($root, $Tree::Nary::PRE_ORDER, $Tree::Nary::TRAVERSE_NON_LEAFS, -1, \&node_build_string, \$tstring);

	print "not " if($tstring !~ /ABFG/);
	print "ok 32\n";

	$tstring = undef;

	Tree::Nary->reverse_children($node_B);
	Tree::Nary->reverse_children($node_G);
	Tree::Nary->traverse($root, $Tree::Nary::LEVEL_ORDER, $Tree::Nary::TRAVERSE_ALL, -1, \&node_build_string, \$tstring);

	print "not " if($tstring !~ /ABFEDCGKJIH/);
	print "ok 33\n";

	# Sort test
	$tstring = undef;

	Tree::Nary->tsort($root);
	Tree::Nary->traverse($root, $Tree::Nary::LEVEL_ORDER, $Tree::Nary::TRAVERSE_ALL, -1, \&node_build_string, \$tstring);
	print "not " if($tstring !~ /ABFCDEGHIJK/);
	print "ok 34\n";

	# Comparison tests
	$returned_node = Tree::Nary->append_data($another_root, "W");

	Tree::Nary->append_data($returned_node, "X");
	Tree::Nary->append_data($returned_node, "A");
	Tree::Nary->append_data($returned_node, "Q");
	Tree::Nary->append_data($returned_node, "S");

	#     We have built:                 Z
	#                                    \
	#                                     W
	#                                   / /\ \
	#                                  X A  Q S

	print "not " if(!Tree::Nary->has_same_struct($node_F, $another_root));
	print "ok 35\n";

	$another_root->{data}= "F";
	$returned_node->{data}= "G";
	Tree::Nary->first_child($returned_node)->{data} = "H";
	Tree::Nary->first_child($returned_node)->{next}->{data} = "I";
	Tree::Nary->last_child($returned_node)->{prev}->{data} = "J";
	Tree::Nary->last_child($returned_node)->{data} = "K";

	print "not " if(!Tree::Nary->is_identical($node_F, $another_root));
	print "ok 36\n";

	# Tree::Nary->DESTROY($root);
}

print "1..36\n";

&test();
