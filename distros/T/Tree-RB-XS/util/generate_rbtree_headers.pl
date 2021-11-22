#! /usr/bin/env perl
use FindBin;
use lib $FindBin::Bin;
use strict;
use warnings;
use RBGen;

RBGen->new(namespace => 'rbtree_')
    ->write_api("./rbtree.h")
    ->write_impl("./rbtree.c");
    #->write_wrapper(
	#	'TreeRBXS_tree.h',
	#	obj_t => 'struct TreeRBXS_item',
	#	tree_t => 'struct TreeRBXS_tree',
	#	node_field => 'rbnode',  # struct SomeType { RBTreeNode_t NodeFieldName; }
	#	cmp => 'TreeRBXS_compare_items'     # int CompareFunc(SomeType *a, SomeType *b);
	#);
