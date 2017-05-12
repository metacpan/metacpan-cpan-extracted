# Developer : Martin Paczynski <nitram@cpan.org>
# Copyright (c) 2003 Martin Paczynski.  All rights reserved.
# Test file for package Tree::FP.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 139 };
use Tree::FP;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $ass_rule;
my $pseudo_pattern = [1,2];

my $tree_node;
my $tree_node2;
my $tree_node3;
my $root_node;

my $header_node;

my $tree;
my $not_tree;
my $faulty_tree;

my @ar_ok;
my @ar_not_ok;


# Test FP_Tree_association_rule object
ok(!($ass_rule = FP_Tree_association_rule->new)); # cannot create empty association rule
ok(!($ass_rule = FP_Tree_association_rule->new($pseudo_pattern))); # cannot create partial association rule
ok(!($ass_rule = FP_Tree_association_rule->new($pseudo_pattern,$pseudo_pattern))); # cannot create partial association rule
ok(!($ass_rule = FP_Tree_association_rule->new($pseudo_pattern,$pseudo_pattern,1))); # cannot create partial association rule
ok(!($ass_rule = FP_Tree_association_rule->new($pseudo_pattern,$pseudo_pattern,0,0))); # cannot create invalid association rule
ok(!($ass_rule = FP_Tree_association_rule->new($pseudo_pattern,$pseudo_pattern,-1,0))); # cannot create invalid association rule
ok(!($ass_rule = FP_Tree_association_rule->new($pseudo_pattern,$pseudo_pattern,0,-1))); # cannot create invalid association rule
ok(!($ass_rule = FP_Tree_association_rule->new($pseudo_pattern,$pseudo_pattern,1,0))); # cannot create invalid association rule
ok(!($ass_rule = FP_Tree_association_rule->new($pseudo_pattern,$pseudo_pattern,0,1))); # cannot create invalid association rule;
ok(!($ass_rule = FP_Tree_association_rule->new($pseudo_pattern,$pseudo_pattern,1.001,1))); # cannot create invalid association rule
ok(!($ass_rule = FP_Tree_association_rule->new($pseudo_pattern,$pseudo_pattern,1,1.001))); # cannot create invalid association rule
ok(!($ass_rule = FP_Tree_association_rule->new($pseudo_pattern,$pseudo_pattern,1.001,1.001))); # cannot create invalid association rule
ok(!($ass_rule = FP_Tree_association_rule->new('a','b',1,1))); # cannot create invalid association rule
ok($ass_rule = FP_Tree_association_rule->new($pseudo_pattern,$pseudo_pattern,1,1)); # create valid association rule;
ok($ass_rule->support); # get support
ok($ass_rule->confidence); # get confidence
ok($ass_rule->left); # get left side of association rule
ok($ass_rule->right); # get right side of association rule


# Test FP_Tree_node object 
ok($root_node = FP_Tree_node->new); # create a root node
ok($root_node->item_name eq ''); # make sure item name is empty string
ok(!$root_node->get_prefix); # check that nothing gets returned by get prefix
ok($root_node->err eq "No pattern generated"); # make sure that error message is correct
ok(!$root_node->get_prefix($root_node)); # check that nothing gets returned by get prefix
ok($root_node->err eq "'get_prefix' called on self or incorrect root provided"); # make sure that error message is correct
ok(!($tree_node = FP_Tree_node->new('a'))); # make sure that node can't be created without a parent if it isn't the root node
ok(($tree_node = FP_Tree_node->new('a',$root_node))); # make sure that node IS created when constructed correctly
ok(!$tree_node->get_prefix($root_node)); # check that nothing gets returned by get prefix
ok($tree_node->err eq 'No pattern generated');# make sure that error message is correct
ok($tree_node->inc_used); # make sure that node used count can be incremented.
ok(!$tree_node->get_prefix($root_node)); # check that nothing gets returned by get prefix
ok($tree_node->err eq 'No pattern generated');# make sure that error message is correct
ok(!($tree_node2 = $tree_node->add_child));# check that adding child without any parameter will not work
ok($tree_node->err eq 'No pattern generated');# make sure that error message is correct
ok(!$tree_node->child_exists('b')); # see that non-existant child does not exist
ok(!$tree_node->children); # see that there are no children
ok($tree_node2 = $tree_node->add_child('b')); # add a child 
ok($tree_node->child_exists('b')); # see if it exists
ok($tree_node->children); # see if children exist
ok($tree_node->count); # see if node has count
ok($tree_node->inc_count(-1)); # see if incrementing count with discarded parameter works
ok($tree_node2->count); # see if other node has count
ok($tree_node2->inc_count(0)); # see if incrementing count with discarded parameter works
ok($tree_node->inc_count); # just crank the count
ok($tree_node->inc_count); # just crank the count
ok($tree_node2->get_prefix($root_node)); # should get something here
ok($tree_node->adj_count); # and something here as well
ok(!$tree_node2->adj_count); # but not here, this node is spent
ok(!$tree_node2->set_sibling($tree_node)); # see that sibling cannot be mismatched
ok($tree_node2->err eq "Sibling 'item name' label not the same as own item name [ sib: a, self: b ]"); # make sure error message is correct
ok($tree_node3 = FP_Tree_node->new('b',$root_node)); # create a lovely sibling
ok($tree_node2->set_sibling($tree_node3)); # and make sure that it gets set properly


# Test the FP_Tree_header_node object
ok(!($header_node = FP_Tree_header_node->new)); # make sure that node cannot be created without parameters
ok(!($header_node = FP_Tree_header_node->new('a'))); # or with just one
ok(!($header_node = FP_Tree_header_node->new('a',0))); # or with the second one set to an incorrect value
ok(!($header_node = FP_Tree_header_node->new('a',-1))); # ditto here
ok($header_node = FP_Tree_header_node->new('a',1)); # this should work however

ok($header_node->rank); # make sure that rank can be gotten
ok($header_node->rank == 1); # and that it was set correctly
ok($header_node->item_name); # and that there is an item name label
ok($header_node->item_name eq 'a'); # and that it is correct
ok($header_node->sibling == undef); # and make sure that no sibling got tossed in accidentally
ok(!$header_node->set_sibling($tree_node3)); # and that false siblings cannot be set
ok($header_node->err eq "Sibling 'item name' label not the same as own item name [ sib: b, self: a ]"); # error message correct, yes?
ok($header_node->set_sibling($tree_node)); # and one big happy family



# Finally, test the Tree::Tree object
ok($tree = Tree::FP->new('i2','i1','i3','i4','i5')); # creates a tree
ok(!(@ar_ok = $tree->association_rules)); # nothing to mine so shouldn't return anything
ok($tree->err eq "Support count equals zero. FP Tree not fully loaded or support level set too low."); # make sure error message correct
ok($faulty_tree = Tree::FP->new('i2','i1','i3','i4','i5')); # just another test to toss in
ok(!($not_tree = Tree::FP->new)); # should not create a tree
ok($tree->insert_tree('i1','i2','i5')); # insert into tree in order
#ok(!(@ar_ok = $tree->association_rules)); # not all nodes loaded
#ok($tree->err eq "Header table node 'i4' has no count."); # error message correct
ok($tree->insert_tree('i2','i4'));# insert into tree in order
ok($tree->insert_tree('i2','i3'));# insert into tree in order
ok($tree->insert_tree('i1','i2','i4'));# insert into tree in order
ok($tree->insert_tree('i1','i3'));# insert into tree in order
ok($tree->insert_tree('i3','i2'));# insert into tree NOT in order
ok($tree->insert_tree('i3','i1'));# insert into tree in order
ok($tree->insert_tree('i1','i2','i5','i3')); # insert into tree in order
ok($tree->insert_tree('i1','i2','i3')); # insert into tree in order
ok(!$tree->insert_tree('a','b','c')); # should fail to insert non-valid values
ok($tree->err =~ /Item '.' not found in Header Table/); # error message correct
ok(!$tree->insert_tree('i5','b','c')); # should fail to insert combination of valid and non-valid values
ok($tree->err =~ /Item '.' not found in Header Table/); # error message correct
ok(!$tree->insert_tree); # should fail to insert when no values passed
ok($tree->err eq "'insert_tree' called with null transaction."); # error message correct
# load faulty data into faulty tree
ok($faulty_tree->insert_tree('i5','i2','i1')); # insert
ok($faulty_tree->insert_tree('i2','i4'));# insert
ok($faulty_tree->insert_tree('i2','i3'));# insert
ok($faulty_tree->insert_tree('i5','i2','i4'));# insert
ok($faulty_tree->insert_tree('i5','i3'));# insert
ok($faulty_tree->insert_tree('i3','i2'));# insert
ok($faulty_tree->insert_tree('i3','i5'));# insert
ok($faulty_tree->insert_tree('i5','i2','i1','i3'));# insert
ok($faulty_tree->insert_tree('i5','i2','i3'));# insert
ok(!$tree->set_support(0)); # supprot cannot be zero
ok($tree->err eq "Support must be a positive value [ 0 ]."); # error message correct
ok(!$tree->set_support(-0.1)); # support cannot be negative
ok($tree->err eq "Support must be a positive value [ -0.1 ]."); # error message correct
ok(!$tree->set_support(1.000001)); #support cannot be greater than 1;
ok($tree->err eq "Support cannot exceed 100% (expressed as a decimal) [ 1.000001 ]."); # error message correct
ok($tree->set_support(0.2)); # Set support
ok(!$tree->set_confidence(0)); # confidence cannot be zero
ok($tree->err eq "Confidence must be a positive value [ 0 ]."); # error message correct
ok(!$tree->set_confidence(-0.1)); # confidence cannot be negative
ok($tree->err eq "Confidence must be a positive value [ -0.1 ]."); # error message correct
ok(!$tree->set_confidence(1.000001)); #confidence cannot be greater than 1;
ok($tree->err eq "Confidence cannot exceed 100% (expressed as a decimal) [ 1.000001 ]."); # error message correct
ok($tree->set_confidence(0.2)); # Set confidence


ok(@ar_ok = $tree->association_rules); # get association rules from tree that is ok
ok(!(@ar_not_ok = $faulty_tree->association_rules)); # should not be able to get association rules from faulty tree;
ok($faulty_tree->err eq "Frequency table not accurate. [6 2]"); # error message correct
ok(@ar_ok = $tree->association_rules); # get association rules from tree that is ok again, extra work, but that's ok.



my $previous_confidence = 1;
my $previous_support = $ar_ok[0]->support;

for(my $e=0; $e <= $#ar_ok; $e++)
	{
	ok($previous_confidence >= $ar_ok[$e]->confidence); # make sure that everything is output in order	
	}
	
ok($tree->reset_tree); # see if tree can be reset
ok(0.2 == $tree->support); # and that the current support is 20%
ok($tree->set_support(0.1)); # that you can change the support
ok(0.1 == $tree->support); # and that it gets changed
ok(0.2 == $tree->confidence); # confidence equal 20%
ok($tree->set_confidence(0.1)); # set it to something else
ok(0.1 == $tree->confidence); # make sure it took hold
ok(@ar_ok = $tree->association_rules); # and see that you can get some association rules from reset tree
ok($previous_support >= $ar_ok[0]->support); # make sure that since we dropped the support, the rules generated are different with different supports
ok($tree->set_support(1));	# Set the support to 100%
ok($tree->reset_tree); # reset the tree
ok(!(@ar_ok = $tree->association_rules)); # there best not be any rules generated with this support level
ok($tree->err eq "No patterns with minimum support of 100% found."); # make sure the error message refects this.

