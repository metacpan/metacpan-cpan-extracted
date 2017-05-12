#!perl

use Test::Most tests => 4;
use Tree::Path::Class;

my $tree;
dies_ok( sub { $tree = Tree::Path::Class->new( {} ) },
    'bad type to constructor' );

$tree = new_ok('Tree::Path::Class');
dies_ok( sub { $tree->set_value( {} ) }, 'bad type to set_value' );

my $child = 'foo';
dies_ok( sub { $tree->add_child($child) }, 'bad type to add_child' );
