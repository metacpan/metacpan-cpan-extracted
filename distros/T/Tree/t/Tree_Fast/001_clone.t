# This test and the corresponding fix was submitted by HDP

use 5.006;

use strict;
use warnings FATAL => 'all';

use Test::More tests => 3;

use_ok( 'Tree::Fast' );

my $tree = Tree::Fast->new('root');

$tree->add_child({}, map { Tree::Fast->new($_) } 1..3);

is($tree->children, 3, 'tree has correct number of children');

my $clone = $tree->clone;

is($clone->children, 3, 'clone has correct number of children');

__END__
