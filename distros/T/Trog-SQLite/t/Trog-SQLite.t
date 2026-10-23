#!/usr/bin/env perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aasx';

# Both import by being loaded, which ProhibitUnusedImports cannot see.
use Test2::V1 -i;                 ## no critic (ProhibitUnusedImports)
use Test2::Plugin::NoWarnings;    ## no critic (ProhibitUnusedImports)
use FindBin::libs;
use File::Temp qw{tempdir};
use File::Slurper::Temp();
use DBI();
use POSIX();
use Time::HiRes();
use DBD::SQLite::Constants qw{SQLITE_LIMIT_VARIABLE_NUMBER};

use Trog::SQLite;

# A directory with a schema in it and the updates named, and the path of the
# schema.  Each update is a string of SQL, in the order of its version.
sub schema_dir {
    my ( $schema, %updates ) = @_;

    my $dir = tempdir( CLEANUP => 1 );
    File::Slurper::Temp::write_text( "$dir/app.sql",            $schema );
    File::Slurper::Temp::write_text( "$dir/app.v$_.update.sql", $updates{$_} ) for keys %updates;

    return ( "$dir/app.sql", "$dir/app.db" );
}

my $V0 = 'CREATE TABLE IF NOT EXISTS things (name TEXT PRIMARY KEY NOT NULL);';
my $V1 = 'ALTER TABLE things ADD COLUMN colour TEXT;';
my $V2 = q{INSERT INTO things (name, colour) VALUES ('sky', 'blue');};

sub version_of { my ($db) = @_; return $db->selectrow_array('SELECT version FROM trog_sqlite_schema_version') }

subtest 'dbh: the schema, and the pragmas that let processes share the file' => sub {
    Trog::SQLite::forget();
    my ( $schema, $file ) = schema_dir($V0);

    my $db = Trog::SQLite::dbh( $schema, $file );
    ok( $db->selectrow_array(q{SELECT 1 FROM sqlite_master WHERE name = 'things'}), 'the schema made its table' );
    is( lc $db->selectrow_array('PRAGMA journal_mode'), 'wal', 'in WAL mode' );
    is( $db->selectrow_array('PRAGMA foreign_keys'),    1,     'with foreign keys enforced' );
    is( $db->selectrow_array('PRAGMA busy_timeout'),    5000,  'and five seconds of patience for a lock' );
    is( version_of($db),                                0,     'a schema with no updates is version 0' );
    ok( $db->{RaiseError}, 'and a failed statement dies' );

    is( Trog::SQLite::dbh( $schema, $file ), $db, 'a second call gets the cached handle' );
    Trog::SQLite::forget();
    ok( Trog::SQLite::dbh( $schema, $file ) != $db, 'and after forget, a new one' );
};

# A file in the default journal mode, as a new one is, where another process
# holds a write transaction open for $seconds.  Returns the pid of that process
# once it holds the lock.
sub hold_write_lock {
    my ( $file, $seconds ) = @_;

    my $setup = DBI->connect( "dbi:SQLite:dbname=$file", q{}, q{}, { RaiseError => 1, PrintError => 0 } );
    $setup->do($V0);
    $setup->disconnect();

    pipe( my $locked_r, my $locked_w ) or die "pipe: $!";
    my $pid = fork() // die "fork: $!";
    if ( !$pid ) {
        close($locked_r) or POSIX::_exit(1);
        my $holder = DBI->connect( "dbi:SQLite:dbname=$file", q{}, q{}, { RaiseError => 1, PrintError => 0 } );
        $holder->do('BEGIN IMMEDIATE');
        $holder->do(q{INSERT INTO things (name) VALUES ('held')});
        print {$locked_w} "locked\n";
        close($locked_w) or POSIX::_exit(1);
        Time::HiRes::sleep($seconds);
        $holder->do('COMMIT');
        POSIX::_exit(0);
    }
    close($locked_w) or die "close: $!";
    my $said = <$locked_r>;
    die "The process that holds the lock said nothing\n" if !defined $said;
    return $pid;
}

subtest 'dbh: a file that another process is writing waits for it, and is still set to WAL' => sub {
    Trog::SQLite::forget();
    my ( $schema, $file ) = schema_dir($V0);
    my $pid = hold_write_lock( $file, 0.5 );

    my $db = eval { Trog::SQLite::dbh( $schema, $file ) };
    waitpid( $pid, 0 );
    ok( $db, 'dbh waits for it rather than dying' ) or diag $@;
    is( lc $db->selectrow_array('PRAGMA journal_mode'), 'wal', 'and sets WAL once the lock is gone' ) if $db;
    is( $?,                                             0,     'and the other process finished its write' );
};

subtest 'dbh: a lock that outlasts the busy timeout is an error' => sub {
    Trog::SQLite::forget();
    my ( undef, $file ) = schema_dir($V0);
    local $Trog::SQLite::BUSY_TIMEOUT = 200;
    my $pid = hold_write_lock( $file, 1 );

    # No schema, so that only the pragmas can fail.
    my $db    = eval { Trog::SQLite::dbh( undef, $file ) };
    my $error = $@;
    waitpid( $pid, 0 );
    is( $db, undef, 'dbh gives up' );
    like( $error, qr/database[ ]is[ ]locked/, 'and says why' );
};

subtest 'dbh: an error other than a lock is not tried again' => sub {
    Trog::SQLite::forget();
    my ( undef, $file ) = schema_dir($V0);

    # Not a read-only file, because root writes one anyway.
    File::Slurper::Temp::write_text( $file, 'not a database ' x 100 );

    my $start = Time::HiRes::time();
    my $db    = eval { Trog::SQLite::dbh( undef, $file ) };
    my $error = $@;
    is( $db, undef, 'dbh refuses a file that is not a database' );
    like( $error, qr/not[ ]a[ ]database/, 'and says why' );
    cmp_ok( Time::HiRes::time() - $start, '<', 1, 'at once, not after the busy timeout' );
};

subtest 'dbh: each update once, in order, on a new database and on an old one' => sub {
    Trog::SQLite::forget();
    my ( $schema, $file ) = schema_dir( $V0, 2 => $V2, 1 => $V1 );

    my $db = Trog::SQLite::dbh( $schema, $file );
    is( version_of($db), 2, 'a new database gets every update' );
    is(
        $db->selectall_arrayref('SELECT name, colour FROM things'),
        [ [qw{sky blue}] ],
        'in the order of their numbers, because v2 needs the column that v1 adds'
    );

    # A second process that opens the same file must not run them again: v2
    # would insert the same primary key twice, and v1 add a column it has.
    Trog::SQLite::forget();
    my $again = Trog::SQLite::dbh( $schema, $file );
    is( version_of($again), 2, 'and opening it again runs nothing' );

    # The database of a program from before it had updates.
    Trog::SQLite::forget();
    my ( undef, $old ) = schema_dir($V0);
    my $before = DBI->connect( "dbi:SQLite:dbname=$old", q{}, q{}, { RaiseError => 1 } );
    $before->do($V0);
    $before->do(q{INSERT INTO things (name) VALUES ('grass')});
    $before->disconnect;

    my $adopted = Trog::SQLite::dbh( $schema, $old );
    is( version_of($adopted),                                                  2,                      'an old database is version 0, and gets every update' );
    is( $adopted->selectall_arrayref('SELECT name FROM things ORDER BY name'), [ ['grass'], ['sky'] ], 'and keeps its rows' );
};

subtest 'dbh: an update that fails changes nothing' => sub {
    Trog::SQLite::forget();
    my ( $schema, $file ) = schema_dir( $V0, 1 => $V1, 2 => "$V2\nINSERT INTO nosuch VALUES (1);" );

    like( dies { Trog::SQLite::dbh( $schema, $file ) }, qr/app[.]v2[.]update[.]sql .* nosuch/, 'it dies, naming the file and what was wrong' );

    my $db = DBI->connect( "dbi:SQLite:dbname=$file", q{}, q{}, { RaiseError => 1 } );
    is( version_of($db),                                     1, 'the version stays at the last update that worked' );
    is( $db->selectrow_array('SELECT count(*) FROM things'), 0, 'and the first statement of the failed update was rolled back with it' );
};

subtest 'dbh: an update that breaks a foreign key is rolled back' => sub {
    Trog::SQLite::forget();
    my $parent = "$V0\nCREATE TABLE IF NOT EXISTS spots (thing TEXT NOT NULL REFERENCES things (name));";
    my ( $schema, $file ) = schema_dir( $parent, 1 => q{INSERT INTO spots VALUES ('nothing');} );

    like( dies { Trog::SQLite::dbh( $schema, $file ) }, qr/break[ ]a[ ]foreign[ ]key .* spots/, 'it says so, and names the table' );
};

subtest 'updates: the files of this schema, and a gap is refused' => sub {
    my ($schema) = schema_dir( $V0, 1 => $V1, 2 => $V2 );
    ( my $dir = $schema ) =~ s{/app[.]sql\z}{};

    # Another schema in the same directory has its own updates, even one whose
    # name ends in the name of this one.
    File::Slurper::Temp::write_text( "$dir/myapp.v1.update.sql", $V1 );
    is( [ Trog::SQLite::updates($schema) ], [ [ 1, "$dir/app.v1.update.sql" ], [ 2, "$dir/app.v2.update.sql" ] ], 'each of its own, in order' );

    my ($gappy) = schema_dir( $V0, 1 => $V1, 3 => $V2 );
    like( dies { Trog::SQLite::updates($gappy) }, qr/skip[ ]version[ ]2 .* app[.]v3[.]update[.]sql/, 'and a missing version stops it before anything runs' );

    my ($none) = schema_dir($V0);
    is( [ Trog::SQLite::updates($none) ], [], 'a schema with no updates has none' );
};

subtest 'schema_version: one row, and it stays one' => sub {
    Trog::SQLite::forget();
    my ( $schema, $file ) = schema_dir($V0);
    my $db = Trog::SQLite::dbh( $schema, $file );

    ok( dies { $db->do('INSERT INTO trog_sqlite_schema_version (version) VALUES (7)') }, 'a second row is refused' );
    ok( dies { $db->do('DELETE FROM trog_sqlite_schema_version') },                      'and so is deleting the one' );
    is( Trog::SQLite::schema_version($db), 0, 'so the version is still the one it was' );
};

subtest 'bulk_insert: many rows, in batches that fit the parameter limit' => sub {
    Trog::SQLite::forget();
    my ( $schema, $file ) = schema_dir('CREATE TABLE IF NOT EXISTS pairs (a INTEGER PRIMARY KEY, b INTEGER);');
    my $db = Trog::SQLite::dbh( $schema, $file );

    # The limit of the oldest builds.  1001 rows of two is 2002 parameters:
    # two full batches of 998, and a short last one, which needs a statement of
    # its own size.
    $db->sqlite_limit( SQLITE_LIMIT_VARIABLE_NUMBER, 999 );
    my @values = map { ( $_, $_ * 2 ) } 1 .. 1001;
    is( Trog::SQLite::bulk_insert( $db, 'pairs', [qw{a b}], 'IGNORE', @values ), 1,    'it returns true' );
    is( $db->selectrow_array('SELECT count(*) FROM pairs'),                      1001, 'every row went in' );
    is( $db->selectrow_array('SELECT b FROM pairs WHERE a = 1001'),              2002, 'with its own values' );

    Trog::SQLite::bulk_insert( $db, 'pairs', [qw{a b}], 'REPLACE', 1, 7 );
    is( $db->selectrow_array('SELECT b FROM pairs WHERE a = 1'), 7, 'REPLACE replaces' );

    like( dies { Trog::SQLite::bulk_insert( $db, 'pairs', [qw{a b}], 'DROP TABLE', 1, 2 ) }, qr/unsupported[ ]insert[ ]action/, 'an action that is not a conflict clause is refused' );
    like( dies { Trog::SQLite::bulk_insert( $db, 'pairs', [], 'IGNORE', 1 ) },               qr/nonempty/,                      'and so are no keys' );
    like( dies { Trog::SQLite::bulk_insert( $db, 'pairs', [qw{a b}], 'IGNORE', 1, 2, 3 ) },  qr/multiple/,                      'and a row that is short a value' );

    # The table and the columns are identifiers, not SQL to paste in.
    ok( dies { Trog::SQLite::bulk_insert( $db, 'pairs (a) VALUES (99); DROP TABLE pairs; --', ['a'], 'IGNORE', 1 ) }, 'a table name that carries SQL is not run' );
    is( $db->selectrow_array('SELECT count(*) FROM pairs'), 1001, 'and the table is still there' );
};

done_testing;
