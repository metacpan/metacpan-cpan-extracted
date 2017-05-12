
use strict;
use warnings;

use Test::More tests => 54;
use Test::NoWarnings;
use Test::Exception;


use URI;

BEGIN {
    use_ok( 'WWW::Sitemapper::Tree' );
};


my $root_uri = URI->new('http://localhost/');
my $root;

lives_ok {
    $root = WWW::Sitemapper::Tree->new(
        uri => $root_uri,
    );
} "root object created";
is $root->id, '0', 'root->id is default and correct';
is $root->uri, $root_uri, 'root->uri is correct';
is scalar @{$root->nodes}, 0, 'root has no nodes';

# child1
my $child1_uri = URI->new('http://localhost/1');
my $child1;
lives_ok {
    $child1 = WWW::Sitemapper::Tree->new(
        uri => $child1_uri,
    );
} "child1 object created";
is $child1->uri, $child1_uri, 'child1->uri is correct';
is $child1->id, '0', 'child1->id is default and correct';


lives_ok {
    $root->add_node( $child1 );
} "child1 added to root";

is $child1->id, '0:0', 'child1->id is updated correctly';
is scalar @{$root->nodes}, 1, 'root has one direct node';
is $root->nodes->[0], $child1, "child1 is root's first node";


is $root->find_node( $child1_uri ), undef, "find_node() cannot find child1";
lives_ok {
    $root->add_to_dictionary( $child1_uri => \$child1 );
} "child1 added to dictionary";

is $root->find_node( $child1_uri ), $child1, "find_node() finds child1";


# child2
my $child2_uri = URI->new('http://localhost/2');
my $child2;
lives_ok {
    $child2 = WWW::Sitemapper::Tree->new(
        uri => $child2_uri,
    );
} "child2 object created";
is $child2->uri, $child2_uri, 'child2->uri is correct';
is $child2->id, '0', 'child2->id is default and correct';


lives_ok {
    $root->add_node( $child2 );
} "child2 added to root";

is $child2->id, '0:1', 'child2->id is updated correctly';
is scalar @{$root->nodes}, 2, 'root has two direct nodes';
is $root->nodes->[1], $child2, "child2 is root's second node";


is $root->find_node( $child2_uri ), undef, "find_node() cannot find child2";
lives_ok {
    $root->add_to_dictionary( $child2_uri => \$child2 );
} "child2 added to dictionary";

is $root->find_node( $child2_uri ), $child2, "find_node() finds child2";


# child11
my $child11_uri = URI->new('http://localhost/1/1');
my $child11;
lives_ok {
    $child11 = WWW::Sitemapper::Tree->new(
        uri => $child11_uri,
    );
} "child11 object created";
is $child11->uri, $child11_uri, 'child11->uri is correct';
is $child11->id, '0', 'child11->id is default and correct';


lives_ok {
    $child1->add_node( $child11 );
} "child11 added to child1";

is $child11->id, '0:0:0', 'child11->id is updated correctly';
is scalar @{$root->nodes}, 2, 'root still has two direct nodes';
is scalar @{$child1->nodes}, 1, 'child1 has one direct node';
is $child1->nodes->[0], $child11, "child11 is root's first node";
is $root->nodes->[0]->nodes->[0], $child11, "child11 is first node of root's first node";


is $root->find_node( $child11_uri ), undef, "find_node() cannot find child11";
lives_ok {
    $root->add_to_dictionary( $child11_uri => \$child11 );
} "child11 added to dictionary";

is $root->find_node( $child11_uri ), $child11, "find_node() finds child11";

# child12
my $child12_uri = URI->new('http://localhost/1/2');
my $child12;
lives_ok {
    $child12 = WWW::Sitemapper::Tree->new(
        uri => $child12_uri,
    );
} "child12 object created";
is $child12->uri, $child12_uri, 'child12->uri is correct';
is $child12->id, '0', 'child12->id is default and correct';


lives_ok {
    $child1->add_node( $child12 );
} "child12 added to child1";

is $child12->id, '0:0:1', 'child12->id is updated correctly';
is scalar @{$root->nodes}, 2, 'root still has two direct nodes';
is scalar @{$child1->nodes}, 2, 'child1 has two direct nodes';
is $child1->nodes->[1], $child12, "child12 is root's second node";
is $root->nodes->[0]->nodes->[1], $child12, "child12 is second node of root's first node";


is $root->find_node( $child12_uri ), undef, "find_node() cannot find child12";
lives_ok {
    $root->add_to_dictionary( $child12_uri => \$child12 );
} "child12 added to dictionary";

is $root->find_node( $child12_uri ), $child12, "find_node() finds child12";



# loc / base_uri
is $child11->loc, $child11->uri, "child11->loc eq child11->uri";

my $child11_base_uri = URI->new('http://localhost/1/1.html');
lives_ok {
    $child11->_base_uri( $child11_base_uri );
} "child11->_base_uri() can be set";

is $child11->_base_uri, $child11_base_uri, "..and is set correctly";

is $child11->loc, $child11->_base_uri, "child11->loc eq child11->_base_uri";


