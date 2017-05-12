#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN { 
    use_ok('Tree::Parser') 
}

my $bad_tree = <<BAD_TREE_CONTENT;
1.0
    1.1
            1.1.1.1
BAD_TREE_CONTENT

my $tp = Tree::Parser->new($bad_tree);

$tp->setParseFilter(sub { undef });

# this should error becuase our filter isnt returning any depth

throws_ok {
    $tp->parse();
} qr/^Parse Error \: Incorrect Value for depth/, '... this should fail';

$tp->setParseFilter(sub { "Fail" });

# this should error becuase our filter isnt returning a proper numeric depth

throws_ok {
    $tp->parse();
} qr/^Parse Error \: Incorrect Value for depth/, '... this should fail';

$tp->setParseFilter(sub { 0 });

# this should error because we are not supplying a node along with the depth

throws_ok {
    $tp->parse();
} qr/^Parse Error \: node is not defined/, '... this should fail';

$tp->useSpaceIndentedFilters();

# this should error becuase our tree is uneven

throws_ok {
    $tp->parse();
} qr/^Parse Error \:/, '... this should fail';

