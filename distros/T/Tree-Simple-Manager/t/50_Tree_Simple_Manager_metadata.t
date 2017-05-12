#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;

BEGIN {
    use_ok('Tree::Simple::Manager');
    use_ok('Tree::Simple::WithMetaData');    
}

{

    my $tree_manager = Tree::Simple::Manager->new(
        'Test Tree' => {
            tree_root       => Tree::Simple::WithMetaData->new(Tree::Simple::WithMetaData->ROOT),
            tree_file_path  => "t/test.tree",
            tree_meta_data  => {
                1  => { desc => 'zero' },
                7  => { desc => 'two point one' },
            }
        }
    );
    isa_ok($tree_manager, 'Tree::Simple::Manager');
    
    {
        my $tree = $tree_manager->getTreeByID("Test Tree" => 1);
        isa_ok($tree, 'Tree::Simple::WithMetaData');
        isa_ok($tree, 'Tree::Simple');
        
        ok($tree->hasMetaDataFor('desc'), '... has metadata for the desc');
        is($tree->getMetaDataFor('desc'), 'zero', '... got metadata for the desc');        
        is($tree->fetchMetaData('desc'), 'zero', '... fetched metadata for the desc');                
    }
    
    
    {
        my $tree = $tree_manager->getTreeByID("Test Tree" => 5);
        isa_ok($tree, 'Tree::Simple::WithMetaData');
        isa_ok($tree, 'Tree::Simple');
        
        ok(!$tree->hasMetaDataFor('desc'), '... has metadata for the desc');    
        is($tree->fetchMetaData('desc'), 'zero', '... fetched metadata for the desc');                
    } 
    
    {
        my $tree = $tree_manager->getTreeByID("Test Tree" => 7);
        isa_ok($tree, 'Tree::Simple::WithMetaData');
        isa_ok($tree, 'Tree::Simple');
        
        ok($tree->hasMetaDataFor('desc'), '... has metadata for the desc');
        is($tree->getMetaDataFor('desc'), 'two point one', '... got metadata for the desc');        
        is($tree->fetchMetaData('desc'), 'two point one', '... fetched metadata for the desc');                
    }    
    
    {
        my $tree = $tree_manager->getTreeByID("Test Tree" => 8);
        isa_ok($tree, 'Tree::Simple::WithMetaData');
        isa_ok($tree, 'Tree::Simple');
        
        ok(!$tree->hasMetaDataFor('desc'), '... has metadata for the desc');
        is($tree->fetchMetaData('desc'), 'two point one', '... fetched metadata for the desc');                
    }       

}
