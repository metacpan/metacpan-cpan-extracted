# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tree-Dag_Node-XPath.t'
# $Id: test_redefine_name.t,v 1.4 2006/02/02 16:18:07 mrodrigu Exp $

#########################

use Test::More tests => 2;
BEGIN { use_ok('Tree::DAG_Node::XPath') };

#########################


# create the tree
my $root = Tree::DAG_Node::XPath->new( { xpath_name_re => qr/([A-Za-z][\w\s]*)/ });
$root->name("root node");
$root->attributes( { id => 'root' });

foreach (1..5)
  { my $new_daughter = $root->new_daughter;
    $new_daughter->name("a daughter");
    $new_daughter->attributes( { 'the id' => $_ , foo => 'bar'});
  }


ok( $root->matches( '//root node') => 'match on root');
