#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 60;
use Test::Exception;

BEGIN {
	use_ok('Tree::Simple::Manager');
    use_ok('Tree::Simple');
}

can_ok('Tree::Simple::Manager', 'new');

{

    my $tree_manager = Tree::Simple::Manager->new(
        'Test Tree' => {
            tree_root      => Tree::Simple->new(Tree::Simple->ROOT),
            tree_file_path => "t/test.tree"
        },
        'Test Tree 2' => {
            tree_root      => Tree::Simple->new(Tree::Simple->ROOT),
            tree_file_path => "t/test2.tree"
        },        
    );
    isa_ok($tree_manager, 'Tree::Simple::Manager');
    
    can_ok($tree_manager, 'getTreeList');
    can_ok($tree_manager, 'getRootTree');
    can_ok($tree_manager, 'getTreeIndex');
    can_ok($tree_manager, 'getTreeByID');    
    can_ok($tree_manager, 'getTreeViewClass');
    can_ok($tree_manager, 'getNewTreeView');    
    
    is_deeply(
        [ sort $tree_manager->getTreeList() ],
        [ 'Test Tree', 'Test Tree 2' ],
        '... got the right list');
    
    is_deeply(
        [ sort @{scalar $tree_manager->getTreeList()} ],
        [ 'Test Tree', 'Test Tree 2' ],
        '... got the right list');
    
    my $tree;
    lives_ok {
        $tree = $tree_manager->getRootTree("Test Tree");
    } '... got the root tree ok';
    ok(defined($tree), '... got a tree back');
    isa_ok($tree, 'Tree::Simple');
    
    my $tree2;
    lives_ok {
        $tree2 = $tree_manager->getRootTree("Test Tree 2");
    } '... got the root tree ok';
    ok(defined($tree2), '... got a tree back');
    isa_ok($tree2, 'Tree::Simple');    
    
    isnt($tree, $tree2, '... got different roots for different trees');
    
    my $II_I_I;
    lives_ok {
        $II_I_I = $tree_manager->getTreeByID('Test Tree' => 8);
    } '... got the tree ok';
    isa_ok($II_I_I, 'Tree::Simple');
    is($II_I_I->getNodeValue(), 'II.I.I', '... got the right node');
    
    throws_ok {
        $tree_manager->getTreeByID('Test Tree 2' => 8);
    } "Tree::Simple::Manager::KeyDoesNotExist", '... got the exception ok';
    
    my $tree_index;
    lives_ok {
        $tree_index = $tree_manager->getTreeIndex("Test Tree");
    } '... got the tree index back ok';
    isa_ok($tree_index, 'Tree::Simple::Manager::Index');
    is($tree_index->getRootTree(), $tree, '... and it is the same as we expected');
    
    my $tree_index2;
    lives_ok {
        $tree_index2 = $tree_manager->getTreeIndex("Test Tree 2");
    } '... got the tree index back ok';
    isa_ok($tree_index2, 'Tree::Simple::Manager::Index');
    is($tree_index2->getRootTree(), $tree2, '... and it is the same as we expected');    
    
    isnt($tree_index, $tree_index2, '... got different roots for different trees indicies');    
    
    my $tree_view_class;
    lives_ok {
        $tree_view_class = $tree_manager->getTreeViewClass("Test Tree");
    } '... got the tree view class okay';
    is($tree_view_class, 'Tree::Simple::View::DHTML', '... got the right view class');

    my $tree_view;
    lives_ok {
        $tree_view = $tree_manager->getNewTreeView("Test Tree");
    } '... got the tree view class okay';
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
}


{
    {
        package My::TreeView;
        use base 'Tree::Simple::View';        
        
        package My::TreeIndex;
        use base 'Tree::Simple::Manager::Index';
        sub new { bless {} } 
    }

    my $tree_manager = Tree::Simple::Manager->new(
        "Test Tree" => {
            tree_root      => Tree::Simple->new(Tree::Simple->ROOT),
            tree_file_path => "t/test.tree",
            tree_index     => 'My::TreeIndex',
            tree_view      => 'My::TreeView',
            }
        );
    isa_ok($tree_manager, 'Tree::Simple::Manager');
    
    my $tree_index = $tree_manager->getTreeIndex("Test Tree");
    isa_ok($tree_index, 'My::TreeIndex');
    
    my $tree_view = $tree_manager->getTreeViewClass("Test Tree");
    is($tree_view, 'My::TreeView', '... got the right view class');
    
}

{ # testing custom parse filter in config

    my $tree_manager = Tree::Simple::Manager->new(
        "Test Tree" => {
            tree_root         => Tree::Simple->new(Tree::Simple->ROOT),
            tree_file_path    => "t/test.tree",
            tree_parse_filter => sub {
                my ($line_iterator, $tree_type) = @_;
                my $line = $line_iterator->next();
                my ($id, $tabs, $node) = ($line =~ /(\d+)\t(\t+)?(.*)/);
                my $depth = 0;
                $depth = length $tabs if $tabs;
                my $tree = $tree_type->new($id);
                $tree->setUID($node);
                return ($depth, $tree);                  
                }
            }
        );
    isa_ok($tree_manager, 'Tree::Simple::Manager');
    
    my $tree_index = $tree_manager->getTreeIndex("Test Tree");
    isa_ok($tree_index, 'Tree::Simple::Manager::Index');
    
    is_deeply(
        [ sort $tree_index->getIndexKeys() ], 
        [ qw(I I.I I.II I.II.I II II.I II.I.I III III.I III.II IV O) ], 
        '... all our keys should be there');    
    
}

# check errors

{
    
    throws_ok {
        Tree::Simple::Manager->new();
    } "Tree::Simple::Manager::InsufficientArguments", '... this should die';
    
    throws_ok {
        Tree::Simple::Manager->new('Fail' => {});
    } "Tree::Simple::Manager::InsufficientArguments", '... this should die';    

    throws_ok {
        Tree::Simple::Manager->new('Fail' => { tree_root => Tree::Simple->new() });
    } "Tree::Simple::Manager::InsufficientArguments", '... this should die';    
    
    throws_ok {
        Tree::Simple::Manager->new('Fail' => { tree_file_path => 1 });
    } "Tree::Simple::Manager::InsufficientArguments", '... this should die';     
    
    throws_ok {
        Tree::Simple::Manager->new(
            'Fail' => { tree_root => Tree::Simple->new(), tree_file_path => "t/test.tree" },
            'Fail' => { tree_root => Tree::Simple->new(), tree_file_path => "t/test.tree" }
            );
    } "Tree::Simple::Manager::DuplicateName", '... this should die';       
    

    throws_ok {
        Tree::Simple::Manager->new(
            'Fail' => { tree_root => bless({}, 'Fail'), tree_file_path => "t/test.tree" },
            );
    } "Tree::Simple::Manager::IncorrectObjectType", '... this should die'; 
    
    throws_ok {
        Tree::Simple::Manager->new(
            'Fail' => { 
                tree_root => Tree::Simple->new(), 
                tree_file_path => "t/test.tree",
                tree_index => "Index::Fail",
            },
        );
    } "Tree::Simple::Manager::IncorrectObjectType", '... this should die'; 
    
    throws_ok {
        Tree::Simple::Manager->new(
            'Fail' => { 
                tree_root => Tree::Simple->new(), 
                tree_file_path => "t/test.tree",
                tree_view => "View::Fail",
            },
        );
    } "Tree::Simple::Manager::IncorrectObjectType", '... this should die';    
    
    throws_ok {
        Tree::Simple::Manager->new(
            'Fail' => { 
                tree_root => Tree::Simple->new(), 
                tree_file_path => "t/test.tree",
                tree_parse_filter => sub { return bless({}, 'Fail') }
            },
        );
    } "Tree::Simple::Manager::OperationFailed", '... this should die';  
    isa_ok($@->getSubException(), 'Tree::Simple::Manager::IncorrectObjectType');  
    
    throws_ok {
        Tree::Simple::Manager->new(
            'Fail' => { 
                tree_root => Tree::Simple->new(), 
                tree_file_path => "t/test.tree",
                tree_parse_filter => [],
            },
        );
    } "Tree::Simple::Manager::OperationFailed", '... this should die';                            
    isa_ok($@->getSubException(), 'Tree::Simple::Manager::IncorrectObjectType');
    
    throws_ok {
        Tree::Simple::Manager->new(
            'Fail' => { tree_root => Tree::Simple->new(), tree_file_path => "t/test.tree.fail" },
            );
    } "Tree::Simple::Manager::OperationFailed", '... this should die';          

    my $tree_manager = Tree::Simple::Manager->new(
        "Test Tree" => {
            tree_root      => Tree::Simple->new(Tree::Simple->ROOT),
            tree_file_path => "t/test.tree"
            }
        );
    isa_ok($tree_manager, 'Tree::Simple::Manager');
    
    throws_ok {
        $tree_manager->getRootTree();
    } "Tree::Simple::Manager::InsufficientArguments", '... this should die';
    
    throws_ok {
        $tree_manager->getRootTree("Fail");
    } "Tree::Simple::Manager::KeyDoesNotExist", '... this should die';
    
    
    throws_ok {
        $tree_manager->getTreeIndex();
    } "Tree::Simple::Manager::InsufficientArguments", '... this should die';
    
    throws_ok {
        $tree_manager->getTreeIndex("Fail");
    } "Tree::Simple::Manager::KeyDoesNotExist", '... this should die';
    
    
    throws_ok {
        $tree_manager->getTreeViewClass();
    } "Tree::Simple::Manager::InsufficientArguments", '... this should die';
    
    throws_ok {
        $tree_manager->getTreeViewClass("Fail");
    } "Tree::Simple::Manager::KeyDoesNotExist", '... this should die';
    
}
