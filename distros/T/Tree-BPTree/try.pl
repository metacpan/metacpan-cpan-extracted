#!/usr/bin/perl

# Quick script I have used for debugging some features.

use Data::Dumper;
use Tree::BPTree;

my $teststr = 'ANDREW STERLING HANENKAMP';
my @splitstr = split //, $teststr;

my $i = 0;
my $tree = Tree::BPTree->new;
print Dumper($tree);
for (@splitstr) {
	$tree->insert($_, $i++);
	print Dumper($tree);
}

# $tree->reverse;
# print Dumper($tree);

my $cursor = $tree->new_cursor;
while (my ($key, $bucket) = $cursor->next) {
	# We must copy here or else iteration will fail!
	my @values = @$bucket;
	for my $value (@values) {
		print "DELETE($key, $value)\n";
		$cursor->delete($value);
		print Dumper($tree);
	}
}
