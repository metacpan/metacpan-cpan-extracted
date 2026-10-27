package Trog::SQLite 0.005;

# ABSTRACT: An SQLite handle with its schema applied, its updates run, and its pragmas set

use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aasx';

use DBI();

# Named so that a missing driver fails here and not inside DBI->connect.
use DBD::SQLite();    ## no critic (ProhibitUnusedImports)
use DBD::SQLite::Constants qw{SQLITE_BUSY SQLITE_LIMIT_VARIABLE_NUMBER};
use File::Basename();
use File::Find();
use File::Slurper();
use List::Util qw{any};
use POSIX      qw{floor};
use Sub::Retry qw{retry};


# The handle cache, keyed by database file, and the process it belongs to.  A
# forked child inherits both, and dbh empties the cache when the process differs.
my $handles = {};
my $owner   = $$;

# How long a statement waits for a lock, in milliseconds, and how long wal
# waits between its tries, in seconds.
our $BUSY_TIMEOUT = 5000;
our $WAL_DELAY    = 0.05;

my %OPTIONS = ( integrity_check => 1 );

sub dbh {
    my ( $schema, $dbname, $options ) = @_;
    $options //= {};
    die "The options of dbh must be a HASH reference\n" unless ref $options eq 'HASH';
    my @unknown = grep { !$OPTIONS{$_} } sort keys %$options;
    die "dbh has no option(s) @unknown\n" if @unknown;

    forget()                   if $owner != $$;
    return $handles->{$dbname} if $handles->{$dbname};

    # No touch first, because DBD::SQLite creates the file on connect.
    my $db = DBI->connect( "dbi:SQLite:dbname=$dbname", q{}, q{}, { RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1 } );

    # Before the schema, because a second process that opens a new database at
    # the same time must wait for the updates of the first one.
    $db->do("PRAGMA busy_timeout = $BUSY_TIMEOUT");

    # Before the schema and the journal mode, so that a damaged file is not written to.
    integrity_check($db) if $options->{integrity_check};
    wal($db);
    $db->do('PRAGMA synchronous = NORMAL');

    if ($schema) {
        apply( $db, $schema );
        update( $db, $schema );
    }

    # SQLite ignores this pragma inside a transaction, and an update that
    # rebuilds a table must not be checked halfway through.
    $db->do('PRAGMA foreign_keys = ON');

    $handles->{$dbname} = $db;
    return $db;
}


sub wal {
    my ($db) = @_;

    my $error;
    retry(
        1 + int( $BUSY_TIMEOUT / 1000 / $WAL_DELAY ),
        $WAL_DELAY,
        sub { $db->do('PRAGMA journal_mode = WAL') },

        # retry dies after its last try only with its default retry_if, so this keeps the error.
        sub { $error = $@; return $error && ( $db->err // 0 ) == SQLITE_BUSY },
    );
    die $error if $error;
    return 1;
}


sub integrity_check {
    my ($db) = @_;

    my @problems = map { $_->[0] } @{ $db->selectall_arrayref('PRAGMA integrity_check') };
    return 1 if "@problems" eq 'ok';
    die 'The integrity check of ' . $db->sqlite_db_filename() . " failed:\n" . join( "\n", @problems ) . "\n";
}


sub apply {
    my ( $db, $file ) = @_;

    # No test first, because read_text dies with the path and the errno.
    my $sql = File::Slurper::read_text($file);
    $db->{sqlite_allow_multiple_statements} = 1;
    my $ok = eval { $db->do($sql); 1 };
    $db->{sqlite_allow_multiple_statements} = 0;
    die "Could not apply $file: " . ( $@ || $db->errstr ) unless $ok;

    return 1;
}


sub updates {
    my ($schema) = @_;

    my $dir  = File::Basename::dirname($schema);
    my $name = File::Basename::basename( $schema, '.sql' );

    # The directory of the schema itself, and nothing below it.
    my %path_of;
    File::Find::find(
        {
            no_chdir => 1,
            wanted   => sub {
                if ( -d $File::Find::name ) {
                    $File::Find::prune = 1 unless $File::Find::name eq $dir;
                    return;
                }
                my $file = File::Basename::basename($File::Find::name);
                my ($version) = $file =~ m/\A\Q$name\E[.]v(\d+)[.]update[.]sql\z/ or return;
                $path_of{$version} = "$dir/$file";
            },
        },
        $dir
    );

    my @versions = sort { $a <=> $b } keys %path_of;
    foreach my $i ( 0 .. $#versions ) {
        my $expected = $i + 1;
        die "The updates of $schema skip version $expected: the next one is $path_of{ $versions[$i] }\n"
          unless $versions[$i] == $expected;
    }

    return map { [ $_, $path_of{$_} ] } @versions;
}


sub schema_version {
    my ($db) = @_;

    # One row, and the triggers keep it one, so that nothing can record two
    # versions or none.
    $db->{sqlite_allow_multiple_statements} = 1;
    $db->do(<<'SQL');
CREATE TABLE IF NOT EXISTS trog_sqlite_schema_version (version INTEGER NOT NULL DEFAULT 0);
CREATE TRIGGER IF NOT EXISTS trog_sqlite_schema_version_one_row
    BEFORE INSERT ON trog_sqlite_schema_version
    WHEN (SELECT count(*) FROM trog_sqlite_schema_version) > 0
    BEGIN SELECT RAISE(ABORT, 'trog_sqlite_schema_version holds one row'); END;
CREATE TRIGGER IF NOT EXISTS trog_sqlite_schema_version_kept
    BEFORE DELETE ON trog_sqlite_schema_version
    BEGIN SELECT RAISE(ABORT, 'trog_sqlite_schema_version holds one row'); END;
INSERT INTO trog_sqlite_schema_version (version)
    SELECT 0 WHERE NOT EXISTS (SELECT 1 FROM trog_sqlite_schema_version);
SQL
    $db->{sqlite_allow_multiple_statements} = 0;

    my ($version) = $db->selectrow_array('SELECT version FROM trog_sqlite_schema_version');
    return $version;
}


sub update {
    my ( $db, $schema ) = @_;

    my $version = schema_version($db);
    foreach my $update ( updates($schema) ) {
        my ( $number, $file ) = @$update;
        next if $number <= $version;

        $db->do('BEGIN IMMEDIATE');
        my $ok = eval {

            # Again inside the lock, because another process can have run it
            # since the read above.
            my ($now) = $db->selectrow_array('SELECT version FROM trog_sqlite_schema_version');
            if ( $number > $now ) {
                apply( $db, $file );

                my $broken = $db->selectall_arrayref('PRAGMA foreign_key_check');
                die "$file leaves " . scalar(@$broken) . " rows that break a foreign key, in the table $broken->[0][0]\n" if @$broken;

                $db->do( 'UPDATE trog_sqlite_schema_version SET version = ?', undef, $number );
            }
            $db->do('COMMIT');
            1;
        };

        unless ($ok) {
            my $err = $@ || "Could not update the schema with $file\n";
            eval { $db->do('ROLLBACK') };    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval) -- report $err, not a failed rollback after it
            die $err;
        }

        $version = $number;
    }

    return $version;
}


sub forget {
    $handles = {};
    $owner   = $$;
    return 1;
}


sub transaction {
    my ( $db, $work ) = @_;

    # begin_work dies rather than nest.
    if ( !$db->{AutoCommit} ) {
        $work->();
        return 1;
    }

    $db->begin_work();
    my $ok = eval { $work->(); $db->commit(); 1 };
    unless ($ok) {
        my $err = $@ || "The transaction failed\n";
        eval { $db->rollback() };    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval) -- report $err, not a failed rollback after it
        die $err;
    }

    return 1;
}


sub bulk_insert {
    my ( $db, $table, $keys, $action, @values ) = @_;
    $action //= 'IGNORE';

    die "unsupported insert action $action\n" unless any { $action eq $_ } qw{ROLLBACK ABORT FAIL IGNORE REPLACE};
    die "keys must be a nonempty ARRAYREF\n"  unless ref $keys eq 'ARRAY' && @$keys;
    die "the number of values must be a multiple of the number of keys\n" if @values % @$keys;

    my $width = @$keys;
    my $limit = floor( $db->sqlite_limit(SQLITE_LIMIT_VARIABLE_NUMBER) / $width ) * $width;

    # Identifiers quoted, and the action checked against its list above.
    my $insert = "INSERT OR $action INTO " . $db->quote_identifier($table) . ' (' . join( ',', map { $db->quote_identifier($_) } @$keys ) . ') VALUES ';    ## no critic (ValuesAndExpressions::PreventSQLInjection) -- quoted identifiers, and an action from a fixed list
    my $tuple  = '(' . join( ',', ('?') x $width ) . ')';

    my ( $statement, $prepared_for ) = ( undef, 0 );
    while (@values) {
        my @params = splice( @values, 0, $limit );
        my $rows   = @params / $width;

        # The last batch is shorter, and needs a statement of its own size.
        ( $statement, $prepared_for ) = ( $db->prepare( $insert . join( ',', ($tuple) x $rows ) ), $rows ) unless $prepared_for == $rows;
        $statement->execute(@params);
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Trog::SQLite - An SQLite handle with its schema applied, its updates run, and its pragmas set

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Trog::SQLite;

    my $dbh = Trog::SQLite::dbh( 'schema/app.sql', '/var/lib/app/app.db' );

    Trog::SQLite::bulk_insert( $dbh, 'tags', [qw{post tag}], 'IGNORE', 1, 'perl', 1, 'sqlite' );

=head1 DESCRIPTION

C<dbh> opens an SQLite database, applies its schema, runs the updates of that
schema that it has not run yet, and sets the pragmas that let several processes
share one database.  It caches the handle, so every later call for that file
gets the same one.

Everything here dies when something goes wrong.

=head2 Schema updates

A schema file holds the first version of the schema, version 0.  Write each
statement in it so that it can run again, such as C<CREATE TABLE IF NOT EXISTS>,
because C<dbh> applies it on every new handle.

A change to the schema after the first version goes in an update file beside
it.  Each update has a number, from 1 up with no gaps, and its name is the name
of the schema with that number:

    schema/app.sql              version 0
    schema/app.v1.update.sql    version 1
    schema/app.v2.update.sql    version 2

Each database records its version in the table C<trog_sqlite_schema_version>.
C<dbh> makes that table in every database that it opens, with one row and a
version of 0.  Then it runs each update with a number above that version, in
order.  Each update runs in one C<BEGIN IMMEDIATE> transaction, together with
the change to the recorded version.  So an update that fails changes nothing,
and the version stays where it was.  When two processes open the database at
the same time, the second one waits for the first, and then finds the update
done.

A new database gets the schema, and then every update.  So the update files
together with the schema describe the current tables, and nobody needs to
change the schema file after its first release.

An update file must not hold C<BEGIN> or C<COMMIT>, because it already runs in
a transaction.  Foreign keys are not enforced while the updates run, so an
update can rebuild a table that other tables refer to.  After each update,
C<PRAGMA foreign_key_check> must report nothing, or the update is rolled back.

=head1 FUNCTIONS

=head2 dbh($schema, $dbname, \%options)

Returns a handle to the database in the file C<$dbname>, which is made if it
does not exist.  If you give C<$schema>, its DDL and its updates are applied
first, as L</Schema updates> says.  Omit C<$schema> for a database that already
has its schema.

C<%options> is optional.  It has one key:

=over 4

=item * C<integrity_check>: when true, run C<integrity_check> on the database
before the schema, and die if the check fails.  The check reads every page, so
it takes as long as the database is large, and it is off unless you ask.

=back

Dies if C<\%options> is not a hash reference, or has a key that is not listed
here.

The handle has C<RaiseError> on, and these pragmas:

=over 4

=item * C<busy_timeout = 5000>, so that a second process waits for five seconds
for a lock rather than failing at once with C<database is locked>.

=item * C<journal_mode = WAL> and C<synchronous = NORMAL>, so that readers do
not block a writer.  SQLite does not wait for a lock to change the journal
mode, so C<wal> tries again for as long as C<busy_timeout> waits.

=item * C<foreign_keys = ON>, set after the updates.

=back

The handle is cached for the rest of the process.  A second call for the same
C<$dbname> returns the cached handle, and does not apply C<$schema> again or
check the database again.  A handle that fails its check is not cached.

Do not call this during C<BEGIN> or outside a sub.

A handle must not outlive a fork.  The cache remembers the process that it
belongs to, so a forked child that calls this gets a new handle of its own,
and the parent keeps its handle.  The child does not need to call C<forget>.

The handle has C<AutoInactiveDestroy> on, so a forked child that drops it, or
exits, does not close it.  Otherwise L<DBI> would roll back an open transaction of
the parent from the child, and SQLite can lose the pages of that transaction
that it already wrote to the WAL.

=head2 wal($db)

Sets the journal mode of the handle C<$db> to WAL, and returns 1.  When another
connection holds a write lock, SQLite fails the change at once with
C<SQLITE_BUSY> and does not wait for C<busy_timeout>.  So this tries again
every C<$WAL_DELAY> seconds, for as long as C<$BUSY_TIMEOUT> says.  Dies with
the last error when the lock outlasts that, and at once on any other error.

=head2 integrity_check($db)

Runs C<PRAGMA integrity_check> on the handle C<$db>, and returns 1 if it
reports C<ok>.  Otherwise dies with the name of the file and every problem that
the check reported, one on each line.

=head2 apply($db, $file)

Runs every statement in the SQL file C<$file> on the handle C<$db>, and returns
1.  Dies if the file cannot be read, or if a statement fails.

=head2 @updates = updates($schema)

Returns the update files of the schema file C<$schema>, as a list of
C<[ $version, $path ]> pairs in the order of their versions.  See
L</Schema updates>.

Dies if the versions have a gap, such as a C<v3> with no C<v2>, because then one
of the files is misnamed or missing, and running the others would skip it.

=head2 $version = schema_version($db)

Returns the version of the schema that the database of C<$db> records.  It makes
the table that records it, with one row and a version of 0, if the database has
none.

=head2 $version = update($db, $schema)

Runs each update of C<$schema> that the database of C<$db> has not run, as
L</Schema updates> says, and returns the version of the database afterwards.
C<dbh> calls this.  Dies with the name of the file if an update fails, and that
update then changes nothing.

=head2 forget()

Drops the cached handles and returns 1, so that the next C<dbh> for each file
opens a new handle.  C<dbh> calls this itself in a forked child.

=head2 transaction($db, $work)

Runs the sub C<$work> in one transaction on the handle C<$db>, and returns 1.
If C<$work> dies, the transaction is rolled back, and this dies with the error
of C<$work>.

If C<$db> is already in a transaction, C<$work> runs in that one, and the code
that began it commits it or rolls it back.  So a sub that needs a transaction
can call this whether or not its caller began one.

=head2 bulk_insert($dbh, $table, \@keys, $action, @values)

Inserts C<@values> into the columns C<@keys> of C<$table>, and returns 1.
C<@values> is one row after another, each with one value for each key:

    my @keys   = qw{A B C};
    my @values = qw{1 2 3 4 5 6 7 8 9};    # three rows

C<$action> is the conflict clause of the C<INSERT>: one of C<ROLLBACK>,
C<ABORT>, C<FAIL>, C<IGNORE> or C<REPLACE>.  With foreign keys off, C<REPLACE>
inserts a row or replaces the one with its key, with less code than
C<ON CONFLICT ... DO UPDATE>.

One statement takes as many parameters as the handle allows, which is 999 in
older builds of SQLite and 32766 in newer ones.  So the rows go in as many
statements as that needs, which reuse one prepared statement.  Split a very
large C<@values> into batches that fit in memory.

Dies if C<$action> is not one of those, if C<@keys> is empty, or if the number
of values is not a multiple of the number of keys.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/Trog-SQLite/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 CONTRIBUTOR

=for stopwords troglodyne-bot

troglodyne-bot <morpheus@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
