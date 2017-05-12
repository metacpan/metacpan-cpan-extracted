#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Exception;

BEGIN {
    use_ok('Tree::Simple');
    use_ok('Tree::Simple::Manager::Index');
}

{
    package Test::Tree::Simple;
    use base 'Tree::Simple';
    sub new {
        my ($class, %desc) = @_;
        my $self = $class->SUPER::new($desc{description});
        $self->setUID($desc{id});
        return $self;
    }
}

my $test_tree = Test::Tree::Simple->new(( id => 9, description => "3.2" ));
isa_ok($test_tree, 'Test::Tree::Simple');

my $tree = Tree::Simple->new(Tree::Simple->ROOT)
            ->addChild(
                Test::Tree::Simple->new(( id => 1, description => "Root" ))
                    ->addChildren(
                    Test::Tree::Simple->new(( id => 2, description => "1" ))
                        ->addChildren(
                        Test::Tree::Simple->new(( id => 6, description => "1.1" )),
                        Test::Tree::Simple->new(( id => 7, description => "1.2" )) 
                        ),
                    Test::Tree::Simple->new(( id => 3, description => "2" )),
                    Test::Tree::Simple->new(( id => 4, description => "3" ))
                        ->addChildren(
                        Test::Tree::Simple->new(( id => 8, description => "3.1" ))
                            ->addChildren(
                            Test::Tree::Simple->new(( id => 11, description => "3.1.1" )),
                            ),
                        $test_tree,
                        Test::Tree::Simple->new(( id => 10, description => "3.3" ))
                            ->addChildren(
                            Test::Tree::Simple->new(( id => 12, description => "3.3.1" )),
                            Test::Tree::Simple->new(( id => 13, description => "3.3.2" ))
                                ->addChild(
                                Test::Tree::Simple->new(( id => 14, description => "3.3.2.1" ))
                                )
                            )
                        ),
                    Test::Tree::Simple->new(( id => 5, description => "4" ))   
                )
            );
isa_ok($tree, 'Tree::Simple'); 

{
    my $index = Tree::Simple::Manager::Index->new($tree);
    isa_ok($index, 'Tree::Simple::Manager::Index');
    
    can_ok($index, 'getIndexKeys');
    can_ok($index, 'getRootTree');
    can_ok($index, 'getTreeByID');
    
    is_deeply(
        [ sort { $a <=> $b } $index->getIndexKeys() ], 
        [ 1 .. 14 ], 
        '... all our keys should be there');

    is_deeply(
        [ sort { $a <=> $b } @{scalar($index->getIndexKeys())} ], 
        [ 1 .. 14 ], 
        '... all our keys should be there');

    is($tree, $index->getRootTree(), '... getting the root gives us the correct object');    
    is($test_tree, $index->getTreeByID(9), '... fetching number 9 gives us the correct object');
    
    ok($index->hasTreeAtID(1), '... got tree we expected');
    ok(!$index->hasTreeAtID(20), '... no tree as expected');    
    
    throws_ok {
        $index->getTreeByID(20);
    } "Tree::Simple::Manager::KeyDoesNotExist", '... this should die';

}

## test our errors too

# constructor errors

throws_ok {
    Tree::Simple::Manager::Index->new();
} "Tree::Simple::Manager::InsufficientArguments", '... this should die';

throws_ok {
    Tree::Simple::Manager::Index->new(1);
} "Tree::Simple::Manager::InsufficientArguments", '... this should die';

throws_ok {
    Tree::Simple::Manager::Index->new([]);
} "Tree::Simple::Manager::InsufficientArguments", '... this should die';

throws_ok {
    Tree::Simple::Manager::Index->new(bless({}, "Fail"));
} "Tree::Simple::Manager::InsufficientArguments", '... this should die';

# test bad trees

my $bad_tree = Tree::Simple->new(Tree::Simple->ROOT)
                ->addChildren(
                Test::Tree::Simple->new(( id => 2, description => "1" ))
                    ->addChildren(
                    Test::Tree::Simple->new(( id => 3, description => "1.1" )),
                    # now add a duplicate id
                    Test::Tree::Simple->new(( id => 2, description => "1.2" )) 
                    )
                );
                
throws_ok {
    Tree::Simple::Manager::Index->new($bad_tree);
} "Tree::Simple::Manager::IllegalOperation", '... this should die';      

