#!usr/bin/env perl

use strict;
use warnings;

use DBI;

use File::Spec;
use File::Temp;

use Tree;
use Tree::Persist;

use Test::More;

# ---------------------------------------------

sub report_tree
{
	my($depth, $tree, $stack) = @_;

	push @$stack, '|--' x $depth . $tree -> value;
	push @$stack, map{@{report_tree($depth + 1, $_, [])} } $tree -> children;

	return $stack;

} # End of report_tree.

# ---------------------------------------------

eval "use DBI";
plan skip_all => "DBI required for testing DB plugin" if $@;

# The EXLOCK option is for BSD-based systems.

my($out_dir) = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
my($file)    = File::Spec -> catfile($out_dir, 'test.sqlite');

plan skip_all => "Temp dir is un-writable" if (! -w $out_dir);

if (! $ENV{DBI_DSN})
{
	eval "use DBD::SQLite";
	plan skip_all => "DBD::SQLite required for testing DB plugin" if $@;

	$ENV{DBI_DSN}  = "dbi:SQLite:dbname=$file";
	$ENV{DBI_USER} = $ENV{DBI_PASS} = '';
}

#use t::tests qw( %runs );

plan tests => 2;

my(@opts)       = ($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS});
my($dbh)        = DBI -> connect(@opts, {RaiseError => 1, PrintError => 0, AutoCommit => 1});
my($table_name) = 'store';

$dbh -> do("drop table if exists $table_name");
$dbh -> do(<<EOS);
create table $table_name
(
	id int not null primary key,
	parent_id int references $table_name(id),
	value varchar(255),
	class varchar(255)
)
EOS

# Create tree.

my($tree_2) = Tree -> new('A') -> add_child
(
	Tree -> new('B'),
	Tree -> new('C') -> add_child
	(
		Tree -> new('D'),
	),
	Tree -> new('E'),
);

# Save tree.

my($persist_2) = Tree::Persist -> create_datastore
({
	type      => 'DB',
	tree      => $tree_2,
	dbh       => $dbh,
	table     => $table_name,
	class_col => 'class',
});

# Create tree.

my($tree_3) = Tree -> new('R') -> add_child
(
	Tree -> new('S'),
	Tree -> new('T'),
);

# Retrieve tree.

my($tree_4) = $persist_2 -> tree;

# Merge trees: Tree from db (4) goes into pre-existing tree (3).

$tree_3 -> add_child($tree_4);

my($expected) = <<EOS;
R
|--S
|--T
|--A
|--|--B
|--|--C
|--|--|--D
|--|--E
EOS
$expected   = [split(/\n/, $expected)];
my($result) = report_tree(0, $tree_3, []);

is_deeply($expected, $result, 'Added tree from db into pre-existing tree, at index 0');

# Create tree.

my($tree_5) = Tree -> new('R') -> add_child
(
	Tree -> new('S'),
	Tree -> new('T'),
);

# Retrieve tree.

my($tree_6) = $persist_2 -> tree;

# Merge trees: Pre-existing tree (5) goes into tree from db (6).

$tree_6 -> add_child({at => 1}, $tree_5);

$expected = <<EOS;
A
|--B
|--R
|--|--S
|--|--T
|--C
|--|--D
|--E
EOS
$expected = [split(/\n/, $expected)];
$result   = report_tree(0, $tree_6, []);

is_deeply($expected, $result, 'Added pre-existing tree into tree from db, at index 1');
