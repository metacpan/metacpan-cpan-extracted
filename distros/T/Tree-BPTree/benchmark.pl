#!/usr/bin/perl

# This script does some tests to compare various things. It uses the same corpus
# that the test scripts use in t/runtests.pl

use strict;
use warnings;

use Benchmark qw(:all);
use Tree::BPTree;

require 't/runtests.pl';
use vars qw( @splitstr );

sub insert_bptree {
	my $tree = Tree::BPTree->new;

	my $i = 0;
	$tree->insert($_, $i++) foreach (@splitstr);

	return $tree;
}

sub insert_hash {
	my $hash = {};
	
	my $i = 0;
	push @{ $$hash{$_} }, $i++ foreach (@splitstr);

	return $hash;
}

sub insert_list {
	my $list = [];

	my $i = 0;
	for my $key (@splitstr) {
		my $pushed = 0;
		SEARCH:
		for my $j (0 .. $#$list) {
			if ($$list[$j][0] eq $key) {
				push @{$$list[$j][1]}, $i++;
				$pushed = 1;
				last SEARCH;
			} elsif ($$list[$j][0] lt $key) {
				splice @$list, $j, 0, [ $key, [ $i++ ] ];
				$pushed = 1;
				last SEARCH;
			}
		}
		push @$list, [ $key, [ $i++ ] ] unless $pushed;
	}

	return $list;
}

print "\nINSERT\n";
print '=' x 60,"\n";
cmpthese(5000,
	{
		'B+'   => \&insert_bptree,
		'Hash' => \&insert_hash,
		'List' => \&insert_list,
	});

my $tree = insert_bptree;
my $hash = insert_hash;
my $list = insert_list;
my ($k, $v);

sub iterate_bptree_each {
	while (($k, $v) = $tree->each) { }
}

sub iterate_bptree_iterate {
	$tree->iterate(sub { $k = $_[0]; $v = $_[1] });
}

sub iterate_bptree_pairs {
	for ($tree->pairs) { ($k, $v) = @$_; }
}

sub iterate_hash {
	my @temp;
	while (my ($k, $v) = each %$hash) {
		push @temp, [ $k, $v ];
	}

	@temp = sort { $a->[0] cmp $b->[0] } @temp;
	for (@temp) { ($k, $v) = @$_; }
}

sub iterate_list {
	for (@$list) { ($k, $v) = @$_; }
}

print "\nORDERED ITERATION\n";
print '=' x 60,"\n";
cmpthese(1000,
	{
		'B+ each'    => \&iterate_bptree_each,
		'B+ iterate' => \&iterate_bptree_iterate,
		'B+ pairs'   => \&iterate_bptree_pairs,
		'Hash'       => \&iterate_hash,
		'List'       => \&iterate_list,
	});

my @values;
sub find_bptree_find {
	for (@splitstr) {
		@values = $tree->find($_);
	}
}

sub find_bptree_grep {
	for my $k (@splitstr) {
		@values = $tree->grep_flattened_values(sub { $_[0] eq $k });
	}
}

sub find_hash {
	for (@splitstr) {
		@values = @{ $$hash{$_} };
	}
}

sub find_list {
	for my $k (@splitstr) {
		@values = grep { $_ eq $k } @$list;
	}
}

print "\nFIND\n";
print '=' x 60,"\n";
cmpthese(5000,
	{
		'B+ find'    => \&find_bptree_find,
#		'B+ grep'    => \&find_bptree_grep, # WAY TO SLOW!
		'Hash'       => \&find_hash,
		'List'       => \&find_list,
	});
