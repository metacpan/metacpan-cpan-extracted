#!/usr/bin/env perl

use Test::More;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../lib";
use lib File::Basename::dirname(__FILE__)."/..";
use lib File::Basename::dirname(__FILE__)."/test_namespace/";
use UR;
use strict;
use warnings;

use Cwd;

plan tests => 38;

our $NAMESPACE = 'Testing';
my $base_dir = Cwd::abs_path(File::Basename::dirname(__FILE__));
our %expected_class_data = (
                Testing => {
                    name  => 'Testing',
                    is    => ['UR::Namespace'],
                    relpath  => 'Testing.pm',
                    file  => 'Testing.pm',
                },
                'Testing::Something' => {
                    name  => 'Testing::Something',
                    is    => ['UR::Object'],
                    relpath  => 'Testing/Something.pm',
                    file  => 'Something.pm',
                },
                'Testing::Something::SubClass1' => {
                    name  => 'Testing::Something::SubClass1',
                    is    => ['Testing::Something'],
                    relpath  => 'Testing/Something/SubClass1.pm',
                    file  => 'SubClass1.pm',
                },
                'Testing::Something::SubClass2' => {
                    name  => 'Testing::Something::SubClass2',
                    is    => ['Testing::Something'],
                    relpath  => 'Testing/Something/SubClass2.pm',
                    file  => 'SubClass2.pm',
                },
                'Testing::Color' => {
                    name  => 'Testing::Color',
                    is    => ['UR::Object'],
                    relpath  => 'Testing/Color.pm',
                    file  => 'Color.pm',
                },
            );

my $cmd = UR::Namespace::Command::Sys::ClassBrowser->create(
                namespace_name => $NAMESPACE,
            );
ok($cmd, 'Created ClassBrowser command');

test_name_cache($cmd);
test_directory_tree_cache($cmd);
test_name_tree_cache($cmd);
test_inheritance_tree_cache($cmd);

sub test_name_cache {
    my $cmd = shift;

    my $by_class_name = $cmd->_generate_class_name_cache('Testing');
    strip_ids(values %$by_class_name); # IDs are random UUIDs

    is_deeply($by_class_name, \%expected_class_data, '_generate__class_name_cache');
}

sub test_directory_tree_cache {
    my $cmd = shift;

    ok( $cmd->_load_class_info_from_modules_on_filesystem($NAMESPACE) ,'_load_class_info_from_modules_on_filesystem');

    my $tree = $cmd->directory_tree_cache($NAMESPACE);
    ok($tree, 'Get directory tree cache');
    ok($tree->has_children, 'Tree root has children');
    is($tree->name, $NAMESPACE, 'Tree root name');
    my $data = strip_ids($tree->data);
    is_deeply($tree->data, $expected_class_data{$NAMESPACE}, 'Tree root data');

    my $children = $tree->children();
    is(scalar(@$children), 3, 'Root has 3 children');

    foreach ( { class => 'Testing::Color', file => 'Color.pm'},
              { class => 'Testing::Something', file => 'Something.pm'} ) {
        is_deeply($tree->get_child($_->{file})->data, $expected_class_data{$_->{class}}, "get_child $_->{file}");
        ok(! $tree->get_child($_->{file})->has_children, "$_->{file} has no children");
    }

    ok(! $tree->get_child('not there'), 'Getting non-existent child returns nothing');

    $tree = $tree->get_child('Something');
    ok($tree, 'Get child directory "Something"');
    ok($tree->has_children, 'directory "Something" has children');
    foreach ( { class => 'Testing::Something::SubClass1', file => 'SubClass1.pm' },
              { class => 'Testing::Something::SubClass2', file => 'SubClass2.pm' } ) {
        is_deeply($tree->get_child($_->{file})->data, $expected_class_data{$_->{class}}, "get_child $_->{file}");
        ok(! $tree->get_child($_->{file})->has_children, "$_->{file} has no children");
    }
}

sub test_name_tree_cache {
    my $cmd = shift;

    ok( $cmd->_load_class_info_from_modules_on_filesystem($NAMESPACE) ,'_load_class_info_from_modules_on_filesystem');
    my $tree = $cmd->name_tree_cache($NAMESPACE);
    ok($tree, 'Get name tree cache');
    ok($tree->has_children, 'Tree root has children');
    is($tree->name, $NAMESPACE, 'Tree root name');
    my $data = strip_ids($tree->data);
    is_deeply($tree->data, $expected_class_data{$NAMESPACE}, 'Tree root data');

    my $children = $tree->children();
    is(scalar(@$children), 2, 'Root has 2 children');

    is_deeply($tree->get_child('Color')->data, $expected_class_data{'Testing::Color'}, 'get child Color');
    ok(! $tree->get_child('Color')->has_children, 'Color has no children');

    $tree = $tree->get_child('Something');
    is_deeply($tree->data, $expected_class_data{'Testing::Something'}, 'Get child "Something"');
    $children = $tree->children;
    is(scalar(@$children), 2, '"Something" has 2 children');
    foreach my $name ( qw( SubClass1 SubClass2 )) {
        my $class = 'Testing::Something::'.$name;
        is_deeply($tree->get_child($name)->data, $expected_class_data{$class}, "Get child $name");
        ok(! $tree->get_child($name)->has_children, "$name has no children");
    }
    
}

sub test_inheritance_tree_cache {
    my $cmd = shift;

    ok( $cmd->_load_class_info_from_modules_on_filesystem($NAMESPACE) ,'_load_class_info_from_modules_on_filesystem');
    my $tree = $cmd->inheritance_tree_cache($NAMESPACE);
    ok($tree, 'Get inheritance tree cache');
    ok($tree->has_children, 'Tree root has children');
    is($tree->name, 'UR::Object', 'UR::Object is the tree root');

    my $visit;
    $visit = sub {
        my $tree = shift;
        return { name => $tree->name,
                 children => [  map { $visit->($_) }
                                sort { $a->name cmp $b->name }
                                @{$tree->children} ],
                };
    };
    my $got_inheritance = $visit->($tree);
            
    my $expected_inheritance = {
            name => 'UR::Object',
            children => [
                    {   name => 'Testing::Color',
                        children => [],
                    },
                    {   name => 'Testing::Something',
                        children => [
                            {   name => 'Testing::Something::SubClass1',
                                children => [],
                            },
                            {   name => 'Testing::Something::SubClass2',
                                children => [],
                            }
                        ],
                    },
                    {   name => 'UR::Singleton',
                        children => [
                            {   name => 'UR::Namespace',
                                children => [
                                    {   name => 'Testing',
                                        children => [],
                                    },
                                ],
                            },
                        ],
                    }
            ]
        };
    is_deeply($got_inheritance, $expected_inheritance, 'Inheritance tree');
}

sub strip_ids {
    delete $_->{id} foreach (@_);
}
