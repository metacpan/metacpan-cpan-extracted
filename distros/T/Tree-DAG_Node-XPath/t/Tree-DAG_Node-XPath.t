# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tree-Dag_Node-XPath.t'
# $Id: Tree-DAG_Node-XPath.t,v 1.8 2006/02/12 08:11:42 mrodrigu Exp $

#########################
use strict;

use Test::More tests => 121;
BEGIN { use_ok('Tree::DAG_Node::XPath') };

#########################

# create the tree
my $root = Tree::DAG_Node::XPath->new();
$root->name("root_node");
$root->attributes( { id => 'root' });

foreach (1..5)
  { my $new_daughter = $root->new_daughter;
    $new_daughter->name("daughter");
    $new_daughter->attributes( { id => "$_" , foo => 'bar'});
  }

# now use XPath to find nodes
my @path2result=( '/root_node/daughter[@id<"3"]' => 'daughter[1]-daughter[2]',

                  '/root_node'                 => 'root_node[root]',
                  '//root_node'                => 'root_node[root]',
                  '/root_node/daughter[@id>3]' => 'daughter[4]-daughter[5]',
                  '/root_node/daughter[@id<"3"]' => 'daughter[1]-daughter[2]',
                  '/root_node/daughter[@id<=3]' => 'daughter[1]-daughter[2]-daughter[3]',
                  '/root_node/daughter[@id!=3]' => 'daughter[1]-daughter[2]-daughter[4]-daughter[5]',
                  '/root_node/daughter[@id=3]' => 'daughter[3]',
                  '//daughter[@id>3]' => 'daughter[4]-daughter[5]',
                  '//daughter[@id<"3"]' => 'daughter[1]-daughter[2]',
                  '//daughter[@id<=3]' => 'daughter[1]-daughter[2]-daughter[3]',
                  '//daughter[@id!=3]' => 'daughter[1]-daughter[2]-daughter[4]-daughter[5]',
                  '//daughter[@id=3]' => 'daughter[3]',
                  '//daughter[@id="3"]' => 'daughter[3]',
                  '//daughter[3]' => 'daughter[3]',
                  '//daughter[3]|daughter[1]' => 'daughter[1]-daughter[3]',
                  '//daughter[3]|/root_node/daughter[1]' => 'daughter[1]-daughter[3]',
                  '//daughter[3]|/root_node' => 'root_node[root]-daughter[3]',

                  '/root_node/daughter[@id>3 and @foo="bar"]' => 'daughter[4]-daughter[5]',
                  '/root_node/daughter[@id<3 and @foo="bar"]' => 'daughter[1]-daughter[2]',
                  '/root_node/daughter[@id<=3 and @foo="bar"]' => 'daughter[1]-daughter[2]-daughter[3]',
                  '/root_node/daughter[@id!=3 and @foo="bar"]' => 'daughter[1]-daughter[2]-daughter[4]-daughter[5]',
                  '/root_node/daughter[@id=3 and @foo="bar"]' => 'daughter[3]',
                  '//daughter[@id>3 and @foo="bar"]' => 'daughter[4]-daughter[5]',
                  '//daughter[@id<3 and @foo="bar"]' => 'daughter[1]-daughter[2]',
                  '//daughter[@id<=3 and @foo="bar"]' => 'daughter[1]-daughter[2]-daughter[3]',
                  '//daughter[@id!=3 and @foo="bar"]' => 'daughter[1]-daughter[2]-daughter[4]-daughter[5]',
                  '//daughter[@id=3 and @foo="bar"]' => 'daughter[3]',
                  '//daughter[@id="3" and @foo="bar"]' => 'daughter[3]',
                  '//daughter[3][@foo="bar"]' => 'daughter[3]',
                  '//daughter[3]|daughter[foo="bar"][1]' => 'daughter[3]',
                  '//daughter[3][@foo="baz"]|/root_node/daughter[1]' => 'daughter[1]',
                  '//daughter[3]|/root_node[@foo="bar"]' => 'daughter[3]',

                  '/root_node/daughter[@id>3 or @foo="bar"]' => 'daughter[1]-daughter[2]-daughter[3]-daughter[4]-daughter[5]',
                  '/root_node/daughter[@id<"3" or @foo="baz"]' => 'daughter[1]-daughter[2]',
                  '/root_node/daughter[@foo="bar"]' => 'daughter[1]-daughter[2]-daughter[3]-daughter[4]-daughter[5]',
                  '/root_node/daughter[@foo!="bar"]' => '',
                );

while( my( $path, $expected_result)= (shift( @path2result), shift( @path2result) ))
  { last unless( $path);
    my @result_nodes= $root->findnodes( $path); 
    is( result_ids( \@result_nodes) => $expected_result, "findnodes $path");
    my $result_nodes= $root->find( $path); 
    is( result_ids( $result_nodes) => $expected_result, "find $path");
  }

my @findvalue_queries=( '//@id' => 'root12345',
                        '//@id|//@foo' => 'rootbar1bar2bar3bar4bar5',
                      );

while( my( $path, $expected_result)= (shift( @findvalue_queries), shift( @findvalue_queries) ))
  { last unless( $path);
    my $value= $root->findvalue( $path); 
    is( $value => $expected_result, "findvalue $path");
  }

my @path_from_root=( 'daughter' => 'daughter[1]-daughter[2]-daughter[3]-daughter[4]-daughter[5]',
                     './daughter' => 'daughter[1]-daughter[2]-daughter[3]-daughter[4]-daughter[5]',
                     '//daughter' => 'daughter[1]-daughter[2]-daughter[3]-daughter[4]-daughter[5]',
                     'daughter[@id="3"]' =>  'daughter[3]',
                     'daughter[@id=3]' =>  'daughter[3]',
                     '//daughter/..' => 'root_node[root]', 'daughter/..' => 'root_node[root]',
                     '//daughter[2]/..' => 'root_node[root]', 'daughter[1]/..' => 'root_node[root]',
                   );
while( my( $path, $expected_result)= (shift( @path_from_root), shift( @path_from_root) ))
  { last unless( $path);
    my @result_nodes= $root->findnodes( $path); 
    is( result_ids( \@result_nodes) => $expected_result, "root->findnodes $path");
    my $result_nodes= $root->find( $path); 
    is( result_ids( $result_nodes) => $expected_result, "root->find $path");
  }

my @root_matches=( '//root_node', '//daughter/..', 'daughter/..', '//daughter[1]/..', 'daughter[5]/..');
foreach my $path ( @root_matches)
  { ok( $root->matches( $path) => "root matches $path"); }


#my @exists=( '//daughter' => 1, 'daughter' => 1, '/daughter' => 0, '//daughter[5]' => 1, '//daughter[6]' => 0,
#             '//daughter[-1]' => 1,);
#while( my( $path, $expected_result)= (shift( @exists), shift( @exists) ))
#  { last unless( $path);
#    is( $root->exists( $path) => $expected_result, "exists $path");  
#  }

# testing node type methods
ok( $root->xpath_is_element_node => "root is element node");

my @root_atts= $root->xpath_get_attributes;
is( $root_atts[0]->xpath_get_value => 'root', "->xpath_get_attributes in list context");
my $root_atts= $root->xpath_get_attributes;
is( $root_atts => 1, "->xpath_get_attributes in scalar context");

my $att= ($root->findnodes( '@id'))[0];
ok( $att->xpath_is_attribute_node => "att is attribute node");
ok( !$att->xpath_is_element_node => "att is not element node");

my $fake_root= $root->xpath_get_parent_node;
ok( $fake_root->xpath_is_document_node => "fake root is not document node");
ok( !$fake_root->xpath_is_element_node => "fake root is not element node");
ok( !$fake_root->xpath_get_parent_node => "fake root does not have a parent");
is( $fake_root->xpath_get_root_node, $fake_root, "fake root is its own root");
ok( !$fake_root->xpath_get_attributes => "fake root has no attributes");
ok( !defined($fake_root->xpath_get_name) => "fake root does not have a name");
ok( !defined($fake_root->xpath_get_next_sibling) => "fake root does not have a next sibling");
ok( !defined($fake_root->xpath_get_previous_sibling) => "fake root does not have a prev sibling");

# testing methods to get nodes content
is( $att->xpath_get_value => 'root', "root id attribute with ->xpath_get_value");
is( $att->to_string => 'id="root"', "root id attribute with to_string");

# testing ->xpath_get_child_nodes
my @children= $root->xpath_get_child_nodes;
is( scalar @children, 5, "->xpath_get_child_nodes in scalar content");

# testing ->xpath_get_child_nodes on fake root
@children= $fake_root->xpath_get_child_nodes;
is( scalar @children, 1, "->xpath_get_child_nodes on fake root in scalar content");

is( ref $root->xpath_get_parent_node, 'Tree::DAG_Node::XPath::Root', '->xpath_get_parent_node on root');
my $daughter= ($root->daughters)[0];
is( ref $daughter->xpath_get_parent_node, 'Tree::DAG_Node::XPath', '->xpath_get_parent_node on daughter');

ok( !$daughter->matches( 'daughter') => "daughter->matches( 'daughter') should be false");
ok( $daughter->matches( 'daughter', $root) => "daughter->matches( 'daughter', \$root) should be true");

sub result_ids
  { return '' unless( $_[0] &&  ( UNIVERSAL::isa( $_[0], 'ARRAY') || UNIVERSAL::isa( $_[0], 'XML::XPath::NodeSet')  ));
    return join( '-', map { $_->name . "[" . $_->attributes->{id} . "]" } @{$_[0]});
  }
