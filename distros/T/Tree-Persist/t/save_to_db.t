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

#use t::tests qw( %runs );

plan tests => 5;

my $CLASS = 'Tree::Persist';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

use_ok( 'Tree' );

# The EXLOCK option is for BSD-based systems.

my(@opts) = ($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS});
my $dbh   = DBI->connect(@opts, {RaiseError => 1, PrintError => 0, AutoCommit => 1});

$dbh->do( <<"__END_SQL__" );
CREATE TEMPORARY TABLE tree_006 (
    id INT NOT NULL PRIMARY KEY
   ,parent_id INT REFERENCES tree_006 (id)
   ,value VARCHAR(255)
   ,class VARCHAR(255) NOT NULL
)
__END_SQL__

$dbh->do( <<"__END_SQL__" );
INSERT INTO tree_006
    ( id, parent_id, value, class )
VALUES
    ( 1, NULL, 'root', 'Tree' )
   ,( 2, NULL, 'root2', 'Tree' )
   ,( 3, 2, 'child', 'Tree' )
__END_SQL__

sub get_values {
    my $dbh = shift;
    my ($table) = @_;
    $table ||= 'tree_006';

    if ( $table eq 'tree_006' ) {
        my $sth = $dbh->prepare_cached( "SELECT * FROM tree_006 WHERE id > 3 ORDER BY id" );
        $sth->execute;
        return $sth->fetchall_arrayref( {} );
    }
    else {
        my $sth = $dbh->prepare_cached( "SELECT * FROM $table ORDER BY id" );
        $sth->execute;
        return $sth->fetchall_arrayref( {} );
    }
}

{
    my $tree = Tree->new( 'root' );

    my $persist = $CLASS->create_datastore({
        type  => 'DB',
        tree  => $tree,
        dbh   => $dbh,
        table => 'tree_006',
        class_col => 'class',
    });

    my $values = get_values( $dbh );
    is_deeply(
        $values,
        [
            { id => 4, parent_id => undef, class => 'Tree', value => 'root' },
        ],
        "We got back what we put in.",
    );

    $dbh->do( "DELETE FROM tree_006 WHERE id > 3" );
}

{
    my $tree = Tree->new( 'A' )->add_child(
        Tree->new( 'B' ),
        Tree->new( 'C' )->add_child(
            Tree->new( 'D' ),
        ),
        Tree->new( 'E' ),
    );

    my $persist = $CLASS->create_datastore({
        type  => 'DB',
        tree  => $tree,
        dbh   => $dbh,
        table => 'tree_006',
        class_col => 'class',
    });

    my $values = get_values( $dbh );
    is_deeply(
        $values,
        [
            { id => 4, parent_id => undef, class => 'Tree', value => 'A' },
            { id => 5, parent_id =>     4, class => 'Tree', value => 'B' },
            { id => 6, parent_id =>     4, class => 'Tree', value => 'C' },
            { id => 7, parent_id =>     4, class => 'Tree', value => 'E' },
            { id => 8, parent_id =>     6, class => 'Tree', value => 'D' },
        ],
        "We got back what we put in.",
    );

    $dbh->do( "DELETE FROM tree_006 WHERE id > 3" );
}

$dbh->do( <<"__END_SQL__" );
CREATE TEMPORARY TABLE tree_006_2 (
    id INT NOT NULL PRIMARY KEY
   ,parent_id INT REFERENCES tree_006_2 (id)
   ,value VARCHAR(255)
)
__END_SQL__

{
    my $tree = Tree->new( 'A' )->add_child(
        Tree->new( 'B' ),
        Tree->new( 'C' )->add_child(
            Tree->new( 'D' ),
            Tree->new( 'E' ),
        ),
    );

    my $persist = $CLASS->create_datastore({
        type  => 'DB',
        tree  => $tree,
        dbh   => $dbh,
        table => 'tree_006_2',
    });

    my $values = get_values( $dbh, 'tree_006_2' );
    is_deeply(
        $values,
        [
            { id => 1, parent_id => undef, value => 'A' },
            { id => 2, parent_id =>     1, value => 'B' },
            { id => 3, parent_id =>     1, value => 'C' },
            { id => 4, parent_id =>     3, value => 'D' },
            { id => 5, parent_id =>     3, value => 'E' },
        ],
        "We got back what we put in.",
    );

    $dbh->do( "DELETE FROM tree_006_2" );
}
