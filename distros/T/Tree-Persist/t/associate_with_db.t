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

plan tests => 10 + 2 * $runs{stats}{plan};

my $CLASS = 'Tree::Persist';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

# The EXLOCK option is for BSD-based systems.

my(@opts) = ($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS});
my $dbh   = DBI->connect(@opts, {RaiseError => 1, PrintError => 0, AutoCommit => 1});

$dbh->do( <<"__END_SQL__" );
CREATE TEMPORARY TABLE tree_007 (
    id INT NOT NULL PRIMARY KEY
   ,parent_id INT REFERENCES tree_007 (id)
   ,class VARCHAR(255) NOT NULL
   ,value VARCHAR(255)
)
__END_SQL__

$dbh->do( <<"__END_SQL__" );
INSERT INTO tree_007
    ( id, parent_id, value, class )
VALUES
    ( 1, NULL, 'root', 'Tree' )
__END_SQL__

sub get_values {
    my $dbh = shift;

    my $sth = $dbh->prepare_cached( "SELECT * FROM tree_007 ORDER BY id" );
    $sth->execute;
    return $sth->fetchall_arrayref( {} );
}

{
    my $persist = $CLASS->connect({
        type  => 'DB',
        dbh   => $dbh,
        table => 'tree_007',
        id    => 1,
        class_col => 'class',
    });

    my $tree = $persist->tree;

    $runs{stats}{func}->( $tree,
        height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
    );
    is( $tree->value, 'root', "The tree's value was loaded correctly" );

    $tree->set_value( 'toor' );

    my $values = get_values( $dbh );
    is_deeply(
        $values,
        [
            { id => 1, parent_id => undef, class => 'Tree', value => 'toor' },
        ],
        "After set_value on parent, everything ok.",
    );

    my $child = Tree->new( 'child' );
    $tree->add_child( $child );

    $values = get_values( $dbh );
    is_deeply(
        $values,
        [
            { id => 1, parent_id => undef, class => 'Tree', value => 'toor' },
            { id => 2, parent_id =>     1, class => 'Tree', value => 'child' },
        ],
        "After first add_child, everything ok",
    );

    my $child2 = Tree->new( 'child2' );
    $tree->add_child( $child2 );

    $values = get_values( $dbh );
    is_deeply(
        $values,
        [
            { id => 1, parent_id => undef, class => 'Tree', value => 'toor' },
            { id => 2, parent_id =>     1, class => 'Tree', value => 'child' },
            { id => 3, parent_id =>     1, class => 'Tree', value => 'child2' },
        ],
        "After second add_child, everything ok",
    );

    $tree->remove_child( $child );

    $values = get_values( $dbh );
    is_deeply(
        $values,
        [
            { id => 1, parent_id => undef, class => 'Tree', value => 'toor' },
            { id => 2, parent_id => undef, class => 'Tree', value => 'child' },
            { id => 3, parent_id =>     1, class => 'Tree', value => 'child2' },
        ],
        "After first remove_child, everything ok",
    );

    $child2->set_value( 'New value' );

    $values = get_values( $dbh );
    is_deeply(
        $values,
        [
            { id => 1, parent_id => undef, class => 'Tree', value => 'toor' },
            { id => 2, parent_id => undef, class => 'Tree', value => 'child' },
            { id => 3, parent_id => 1, class => 'Tree', value => 'New value' },
        ],
        "After child set_value, everything ok",
    );

    $child->set_value( 'Not reflected' );

    $values = get_values( $dbh );
    is_deeply(
        $values,
        [
            { id => 1, parent_id => undef, class => 'Tree', value => 'toor' },
            { id => 2, parent_id => undef, class => 'Tree', value => 'child' },
            { id => 3, parent_id => 1, class => 'Tree', value => 'New value' },
        ],
        "After removed child set_value, the DB wasn't affected",
    );

    my $grandchild = Tree->new( 'grandchild' );
    $child2->add_child( $grandchild );

    $values = get_values( $dbh );
    is_deeply(
        $values,
        [
            { id => 1, parent_id => undef, class => 'Tree', value => 'toor' },
            { id => 2, parent_id => undef, class => 'Tree', value => 'child' },
            { id => 3, parent_id => 1, class => 'Tree', value => 'New value' },
            { id => 4, parent_id => 3, class => 'Tree', value => 'grandchild' },
        ],
        "After removed child set_value, the DB wasn't affected",
    );

}

{
    my $persist = $CLASS->connect({
        type  => 'DB',
        dbh   => $dbh,
        table => 'tree_007',
        id    => 3,
    });

    my $tree = $persist->tree;

    $runs{stats}{func}->( $tree,
        height => 2, width => 1, depth => 0, size => 2, is_root => 1, is_leaf => 0,
    );
    is( $tree->value, 'New value', "The tree's value was loaded correctly" );
}
