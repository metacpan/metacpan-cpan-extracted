use Test::Pod::Coverage tests=>1;

use warnings;
use strict;

pod_coverage_ok(
	"Tree::Trie",
	{ also_private => ['DEFAULT_END_MARKER'] },
	"Tree::Trie is covered"
);
