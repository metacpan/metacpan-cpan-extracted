#!perl

use Modern::Perl;
use Test::Most tests => 16;

use Path::Class;
use Tree;
use Tree::Path::Class;

my $tree = new_ok( 'Tree::Path::Class' => [ dir('test_dir') ], 'test root' );
isa_ok( $tree->value, 'Path::Class::Dir', 'root value' );
isa_ok( $tree->path,  'Path::Class::Dir', 'root path' );
is( $tree->path->stringify, 'test_dir', 'root path string' );

$tree->set_value( dir('another_dir') );
is( $tree->path->stringify, 'another_dir', 'root path changes with value' );

my $child = new_ok(
    'Tree::Path::Class' => ['child_dir'],
    'string constructor',
);
lives_ok( sub { $tree->add_child($child) }, 'add child' );
is_deeply(
    [ $child->path->dir_list ],
    [qw(another_dir child_dir)],
    'path with child',
);

my $child_file = new_ok(
    'Tree::Path::Class' => [ file('foo.txt') ],
    'new with file',
);
lives_ok( sub { $tree->add_child($child_file) }, 'add child file' );
isa_ok( $child_file->value, 'Path::Class::File', 'child file' );
is_deeply(
    [ $child_file->path->dir->dir_list, $child_file->value->stringify ],
    [qw(another_dir foo.txt)], 'path with child file',
);

my $empty_tree = new_ok( 'Tree::Path::Class' => [], 'new empty tree' );
is( $empty_tree->value, undef, 'undef root value' );
is( $empty_tree->path,  undef, 'undef root path' );

my $plain_child = Tree->new();
lives_ok( sub { $empty_tree->add_child($plain_child) },
    'add plain Tree child' );
