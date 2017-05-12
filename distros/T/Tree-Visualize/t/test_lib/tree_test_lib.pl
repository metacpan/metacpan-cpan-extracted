
use strict;
use warnings;

use Tree::Binary::Search;
use Tree::Simple;

sub balanced_tree_binary {
    my ($num_nodes) = @_;
    
    my $btree = Tree::Binary::Search->new();
    $btree->useNumericComparison();
    
    my @numbers = (7, 
                   3,
                     1, 
                       0, 2,
                     5,  
                       4, 6, 
                   11, 
                     9, 
                       10, 8,
                     13, 
                       12, 14
                   );

    foreach my $num (@numbers) {
        $btree->insert($num => $num);
    }
    
    return $btree;
}

sub rand_tree_binary {
    my ($num_nodes) = @_;
    my $ceil = $num_nodes * 2;    
    
    my $btree = Tree::Binary::Search->new();
    $btree->useNumericComparison();
    
    for (0 .. $num_nodes) {
        my $num = rand_num($ceil);
        while ($btree->exists($num)) {
            $num = rand_num($ceil);
        }
        $btree->insert($num => $num);
    }
    
    return $btree;
}

## --------------------------------------------------------

sub rand_tree_simple {
    my ($max_nodes) = @_;
    my $root = Tree::Simple->new(Tree::Simple->ROOT);    
    my $current = $root;
    while ($max_nodes) {
        my $dir = rand_num(4);
        $max_nodes--;
        my $num_string = $max_nodes; 
        if ($dir == 1) {
            # add child
            my $t = Tree::Simple->new($num_string); 
            $current->addChild($t);
        }
        elsif ($dir == 2) {
            # add child or insert sibling at
            # a random index then move current 
            # value to that node
            my $t = Tree::Simple->new($num_string); 
            if ($current->isRoot()) {
                $current->addChild($t);
            }
            else {
                $current->insertSibling(rand_num($current->getParent()->getChildCount()), $t);
            }
            $current = $t;             
        }
        elsif ($dir == 3) {
            # insert a child at a random index
            # or add a child and change to that 
            # child node
            my $t = Tree::Simple->new($num_string); 
            unless ($current->isLeaf()) {
                $current->insertChild(rand_num($current->getChildCount()), $t);
            }
            else {
                $current->addChild($t);              
            }
            $current = $t;              
        }
        elsif ($dir == 4) {
            # traverse up to the parent
            # in a semi-random fashion
            while (rand_num($current->getDepth()) > ($current->getDepth() / 2)) {
                last if $current->isRoot();
                $current = $current->getParent();
            }
        }
    }
    return $root;
}

## --------------------------------------------------------

sub rand_num {
    my ($ceil) = @_;
    my $num = ((rand() * $ceil) % $ceil);
    $num++ if $num == 0;
    return $num;
}


1;