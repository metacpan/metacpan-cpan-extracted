#!/usr/bin/env perl

use lib '.';
use strict;
use warnings;

use File::Spec;
use File::Temp;

use Test::More;

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

use t::tests qw( %runs );

plan tests => 11 + 6 * $runs{stats}{plan};

my $CLASS = 'Tree::Persist';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

my(@opts) = ($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS});
my $dbh   = DBI->connect(@opts, {RaiseError => 1, PrintError => 0, AutoCommit => 1});

$dbh->do( <<"__END_SQL__" );
CREATE TEMPORARY TABLE tree_005 (
    id INT NOT NULL PRIMARY KEY
   ,parent_id INT REFERENCES tree_005 (id)
   ,class VARCHAR(255) NOT NULL
   ,value VARCHAR(255)
)
__END_SQL__

$dbh->do( <<"__END_SQL__" );
INSERT INTO tree_005
    ( id, parent_id, value, class )
VALUES
    ( 1, NULL, 'root', 'Tree' )
   ,( 2, NULL, 'root2', 'Tree' )
   ,( 3, 2, 'child', 'Tree' )
__END_SQL__

{
    my $persist = $CLASS->connect({
        type  => 'DB',
        dbh   => $dbh,
        table => 'tree_005',
        id    => 1,
        class_col => 'class',
    });

    my $tree = $persist->tree();
    isa_ok( $tree, 'Tree' );

    $runs{stats}{func}->( $tree,
        height => 1, width => 1, depth => 0,
        size => 1, is_root => 1, is_leaf => 1,
    );
    is( $tree->value, 'root', "The tree's value was loaded correctly" );
}

{
    my $persist = $CLASS->connect({
        type  => 'DB',
        dbh   => $dbh,
        table => 'tree_005',
        id    => 2,
        class_col => 'class',
    });

    my $tree = $persist->tree();

    isa_ok( $tree, 'Tree' );

    $runs{stats}{func}->( $tree,
        height => 2, width => 1, depth => 0, size => 2, is_root => 1, is_leaf => 0,
    );
    is( $tree->value, 'root2', "The tree's value was loaded correctly" );

    my ($child) = $tree->children;

    $runs{stats}{func}->( $child,
        height => 1, width => 1, depth => 1, size => 1, is_root => 0, is_leaf => 1,
    );
    is( $child->value, 'child', "The tree's value was loaded correctly" );
}

$dbh->do( <<"__END_SQL__" );
CREATE TEMPORARY TABLE tree_005_2 (
    some_id INT NOT NULL PRIMARY KEY
   ,some_parent_id INT REFERENCES tree_005 (id)
   ,some_class VARCHAR(255) NOT NULL
   ,some_value VARCHAR(255)
)
__END_SQL__

$dbh->do( <<"__END_SQL__" );
INSERT INTO tree_005_2
    ( some_id, some_parent_id, some_value, some_class )
VALUES
    ( 1, NULL, 'root', 'Tree' )
   ,( 2, NULL, 'root2', 'Tree' )
   ,( 3, 2, 'child', 'Tree' )
__END_SQL__

{
    my $persist = $CLASS->connect({
        type  => 'DB',
        dbh   => $dbh,
        table => 'tree_005_2',
        id    => 1,
        id_col => 'some_id',
        parent_id_col => 'some_parent_id',
        value_col => 'some_value',
        class_col => 'some_class',
    });

    my $tree = $persist->tree();
    isa_ok( $tree, 'Tree' );

    $runs{stats}{func}->( $tree,
        height => 1, width => 1, depth => 0,
        size => 1, is_root => 1, is_leaf => 1,
    );
    is( $tree->value, 'root', "The tree's value was loaded correctly" );
}

{
    my $persist = $CLASS->connect({
        type  => 'DB',
        dbh   => $dbh,
        table => 'tree_005_2',
        id    => 2,
        id_col => 'some_id',
        parent_id_col => 'some_parent_id',
        value_col => 'some_value',
        class => 'Tree::Persist::DB::SelfReferential',
    });

    my $tree = $persist->tree();

    isa_ok( $tree, 'Tree' );

    $runs{stats}{func}->( $tree,
        height => 2, width => 1, depth => 0, size => 2, is_root => 1, is_leaf => 0,
    );
    is( $tree->value, 'root2', "The tree's value was loaded correctly" );

    my ($child) = $tree->children;

    $runs{stats}{func}->( $child,
        height => 1, width => 1, depth => 1, size => 1, is_root => 0, is_leaf => 1,
    );
    is( $child->value, 'child', "The tree's value was loaded correctly" );
}
