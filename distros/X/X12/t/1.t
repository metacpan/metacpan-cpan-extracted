# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'
#########################
use strict;
use Test;
BEGIN { plan tests => 15 }
#########################
use FindBin;
use X12::Parser::Tree;

#setup for the test
my $root = X12::Parser::Tree->new();
$root->set_name('X12');

#add 1 child
my $child = X12::Parser::Tree->new();
$child->set_name('ST');
$child->set_loop_start_parm( 'ST', '', '' );
$child->set_parent($root);
$root->add_child($child);

#add 2 child
$child = X12::Parser::Tree->new();
$child->set_name('2000A');
$child->set_loop_start_parm( 'HL', '3', '20' );
$child->set_parent($root);
$root->add_child($child);

#add 2.1 child
my $grandchild = X12::Parser::Tree->new();
$grandchild->set_name('2010AA');
$grandchild->set_loop_start_parm( 'NM1', '1', '85' );
$grandchild->set_parent($child);
$child->add_child($grandchild);

#add 2.2 child
$grandchild = X12::Parser::Tree->new();
$grandchild->set_name('2010AB');
$grandchild->set_loop_start_parm( 'NM1', '1', '87' );
$grandchild->set_parent($child);
$child->add_child($grandchild);

#add 3 child
$child = X12::Parser::Tree->new();
$child->set_name('2000B');
$child->set_loop_start_parm( '2000B', '3', '22' );
$child->set_parent($root);
$root->add_child($child);

#add 3.1 child
$grandchild = X12::Parser::Tree->new();
$grandchild->set_name('2010BA');
$grandchild->set_loop_start_parm( 'NM1', '1', 'IL' );
$grandchild->set_parent($child);
$child->add_child($grandchild);

#add 3.2 child
$grandchild = X12::Parser::Tree->new();
$grandchild->set_name('2010BB');
$grandchild->set_loop_start_parm( 'NM1', '1', 'PR,QD,AO' );
$grandchild->set_parent($child);
$child->add_child($grandchild);
my $svalue = '';
my $ivalue = 0;

#test
my $node = $root;
$svalue = $node->get_name;
ok( $svalue, 'X12' );

#test
$ivalue = $node->is_root;
ok( $ivalue, 1 );

#test
$svalue = $node->get_parent;
ok( $svalue, undef );

#test
$ivalue = $node->has_children;
ok( $ivalue, 1 );

#test 5
$ivalue = $node->get_child_count;

#test
ok( $ivalue, 3 );

#test
$child  = $node->get_child(0);
$svalue = $child->get_name();
ok( $svalue, 'ST' );

#test
$child  = $node->get_child(2);
$svalue = $child->get_name();
ok( $svalue, '2000B' );

#test
$node   = $child;
$ivalue = $node->has_children();
ok( $ivalue, 1 );

#test
$ivalue = $node->get_child_count;
ok( $ivalue, 2 );

#test
$child  = $node->get_child(0);
$svalue = $child->get_name();
ok( $svalue, '2010BA' );

#test
$node = $child;
my $arrayref = [ 'NM1', 'IL', '2', 'GREEN HOSPITAL' ];
$ivalue = $node->is_loop_start($arrayref);
ok( $ivalue, 1 );

#test
$arrayref = [ 'NM1', 'QC', '2', 'GREEN HOSPITAL' ];
$ivalue = $node->is_loop_start($arrayref);
ok( $ivalue, 0 );

#test
$node   = $node->get_parent;
$node   = $node->get_child(1);
$svalue = $node->get_name();
ok( $svalue, '2010BB' );

#test
$arrayref = [ 'NM1', 'QD', '2', 'GREEN HOSPITAL' ];
$ivalue = $node->is_loop_start($arrayref);
ok( $ivalue, 1 );

#test
$arrayref = [ 'NM1', 'QC', '2', 'GREEN HOSPITAL' ];
$ivalue = $node->is_loop_start($arrayref);
ok( $ivalue, 0 );
