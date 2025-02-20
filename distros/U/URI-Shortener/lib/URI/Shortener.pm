package URI::Shortener 1.004;

#ABSTRACT: Shorten URIs so that you don't have to rely on external services

use strict;
use warnings;

use v5.012;

use Capture::Tiny qw{capture_merged};
use Carp::Always;
use POSIX qw{floor};
use DBI;
use DBD::SQLite;
use DBD::Pg;
use DBD::mysql;
use File::Touch;
use Crypt::PRNG;


my $SCHEMA_NAMES = {
    uri_tablename    => 'uris',
    prefix_tablename => 'prefix',
    uri_idxname      => 'uri_idx',
    prefix_idxname   => 'prefix_idx',
    cipher_idxname   => 'cipher_idx',
    created_idxname  => 'created_idx',
};

our $SCHEMA_SQLITE = qq{
CREATE TABLE IF NOT EXISTS prefix_tablename (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    prefix TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS uri_tablename (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    prefix_id INTEGER NOT NULL REFERENCES prefix_tablename(id) ON DELETE CASCADE,
    uri TEXT NOT NULL UNIQUE,
    cipher TEXT DEFAULT NULL UNIQUE,
    created INTEGER
);

CREATE INDEX IF NOT EXISTS uri_idxname     ON uri_tablename(uri);
CREATE INDEX IF NOT EXISTS prefix_idxname  ON prefix_tablename(prefix);
CREATE INDEX IF NOT EXISTS cipher_idxname  ON uri_tablename(cipher);
CREATE INDEX IF NOT EXISTS created_idxname ON uri_tablename(created);
};

our $SCHEMA_PG = qq{
CREATE TABLE IF NOT EXISTS prefix_tablename (
    id SERIAL PRIMARY KEY,
    prefix TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS uri_tablename (
    id BIGSERIAL PRIMARY KEY,
    prefix_id INTEGER NOT NULL REFERENCES prefix_tablename(id) ON DELETE CASCADE,
    uri TEXT NOT NULL UNIQUE,
    cipher TEXT DEFAULT NULL UNIQUE,
    created INTEGER
);

CREATE INDEX IF NOT EXISTS uri_idxname     ON uri_tablename(uri);
CREATE INDEX IF NOT EXISTS prefix_idxname  ON prefix_tablename(prefix);
CREATE INDEX IF NOT EXISTS cipher_idxname  ON uri_tablename(cipher);
CREATE INDEX IF NOT EXISTS created_idxname ON uri_tablename(created);
};

our $SCHEMA_MYSQL = qq{
CREATE TABLE IF NOT EXISTS prefix_tablename (
    id INTEGER AUTO_INCREMENT,
    prefix TEXT NOT NULL,
    PRIMARY KEY(id)
);

CREATE TABLE IF NOT EXISTS uri_tablename (
    id BIGINT AUTO_INCREMENT,
    prefix_id INTEGER NOT NULL REFERENCES prefix_tablename(id) ON DELETE CASCADE,
    uri TEXT NOT NULL,
    cipher VARCHAR(180) DEFAULT NULL UNIQUE,
    created INTEGER,
    PRIMARY KEY(id)
);

};


sub new {
    my $class = shift;
    my %options = (
        %$SCHEMA_NAMES,
        @_
    );
    $options{dbtype} //= 'sqlite';

    $options{domain} ||= join('',('a'..'z','A'..'Z'));

    foreach my $required (qw{domain prefix dbname seed}) {
        die "$required required" unless $options{$required};
    }
    $options{length} = 12 if !$options{length} || $options{length} < 0;

    # Strip trailing slash from prefix
    $options{prefix} =~ s|/+$||;

    $options{sqlite_schema} = $SCHEMA_SQLITE;
    $options{mysql_schema}  = $SCHEMA_MYSQL;
    $options{pg_schema}     = $SCHEMA_PG;

    # Mongle the schema appropriately
    foreach my $sql_obj (keys(%$SCHEMA_NAMES)) {
        $options{sqlite_schema} =~ s/\Q$sql_obj\E/$options{$sql_obj}/gmx;
        $options{mysql_schema}  =~ s/\Q$sql_obj\E/$options{$sql_obj}/gmx;
        $options{pg_schema}     =~ s/\Q$sql_obj\E/$options{$sql_obj}/gmx;
    }

    $options{dbh} = {};

    return bless( \%options, $class );
}


sub cipher {
    my ( $self, $id ) = @_;
    my $rr = Crypt::PRNG->new('Fortuna', $self->{seed} + $id);
    return $rr->string_from($self->{domain}, $self->{length});
}


my $smash=0;
sub shorten {
    my ( $self, $uri ) = @_;

    my $query = "SELECT id, cipher FROM $self->{uri_tablename} WHERE uri=?";

    my $rows = $self->_dbh()->selectall_arrayref( $query, { Slice => {} }, $uri );
    $rows //= [];
    if (@$rows) {
        return $self->{prefix}."/".$rows->[0]{cipher} if $rows->[0]{cipher};
        my $ciphered = $self->cipher( $rows->[0]{id} );
        my $worked = $self->_dbh()->do( "UPDATE $self->{uri_tablename} SET cipher=? WHERE id=?", undef, $ciphered, $rows->[0]{id} );
        # In the (incredibly rare) event of a collision, just burn the row and move on.
        if (!$worked) {
            warn "DANGER: cipher collision detected.";
            $self->_dbh()->do( "UPDATE $self->{uri_tablename} SET uri=? WHERE id=?", undef, "$uri-BURNED$smash", $rows->[0]{id} ) or die "Could not burn row";
            $smash++;
            die "Too many failures to avoid name collisions encountered, prune your DB!" if $smash > 64;
            goto \&shorten;
        }
        return $self->{prefix} . "/" . $ciphered;
    }

    # Otherwise we need to store the URI and retrieve the ID.
    my $pis        = "SELECT id FROM $self->{prefix_tablename} WHERE prefix=?";
    my $has_prefix = $self->_dbh->selectall_arrayref( $pis, { Slice => {} }, $self->{prefix} );
    unless (@$has_prefix) {
        $self->_dbh()->do( "INSERT INTO $self->{prefix_tablename} (prefix) VALUES (?)", undef, $self->{prefix} ) or die $self->_dbh()->errstr;
    }

    my $qq = "INSERT INTO $self->{uri_tablename} (uri,created,prefix_id) VALUES (?,?,(SELECT id FROM $self->{prefix_tablename} WHERE prefix=?))";
    $self->_dbh()->do( $qq, undef, $uri, time(), $self->{prefix} ) or die $self->_dbh()->errstr;
    goto \&shorten;
}


sub lengthen {
    my ( $self, $uri ) = @_;
    my ($cipher) = $uri =~ m|^\Q$self->{prefix}\E/(.*)$|;

    my $query = "SELECT uri FROM $self->{uri_tablename} WHERE cipher=? AND prefix_id IN (SELECT id FROM $self->{prefix_tablename} WHERE prefix=?)";

    my $rows = $self->_dbh()->selectall_arrayref( $query, { Slice => {} }, $cipher, $self->{prefix} );
    $rows //= [];
    return unless @$rows;
    return $rows->[0]{uri};
}


sub prune_before {
    my ( $self, $when ) = @_;
    $self->_dbh()->do( "DELETE FROM $self->{uri_tablename} WHERE created < ?", undef, $when ) or die $self->_dbh()->errstr;
    return 1;
}

my %db_dispatch = (
    sqlite => \&_sqlite_dbh,
    pg     => \&_pg_dbh,
    mysql  => \&_my_dbh,
);

sub _dbh {
    my ($self) = @_;
    return $db_dispatch{$self->{dbtype}}->(@_);
}

sub _sqlite_dbh {
    my ($self) = @_;
    my $dbname = $self->{dbname};
    return $self->{dbh}->{$dbname} if exists $self->{dbh}->{$dbname};

    # Some systems splash down without this.  YMMV.
    File::Touch::touch($dbname) if $dbname ne ':memory:' && !-f $dbname;

    my $db = DBI->connect( "dbi:SQLite:dbname=$dbname", "", "" );
    $db->{sqlite_allow_multiple_statements} = 1;
    $db->do($self->{sqlite_schema}) or die "Could not ensure database consistency: " . $db->errstr;
    $db->{sqlite_allow_multiple_statements} = 0;
    $self->{dbh}->{$dbname} = $db;

    # Turn on fkeys
    $db->do("PRAGMA foreign_keys = ON") or die "Could not enable foreign keys";

    # Turn on WALmode, performance
    $db->do("PRAGMA journal_mode = WAL") or die "Could not enable WAL mode";

    return $db;
}

sub _pg_dbh {
    my ($self) = @_;
    my $dbname = $self->{dbname};
    return $self->{dbh}->{$dbname} if exists $self->{dbh}->{$dbname};

    my $host = $self->{dbhost} // $ENV{PGHOST} || 'localhost';
    my $port = $self->{dbport} // $ENV{PGPORT} || 5432;
    my $user = $self->{dbuser} // $ENV{PGUSER};
    my $pass = $self->{dbpass} // $ENV{PGPASSWORD};

    my $db = DBI->connect("dbi:Pg:dbname=$dbname;host=$host;port=$port", $user, $pass);

    #XXX pg is noisy even when you say 'IF NOT EXISTS'
    my $result;
    capture_merged { $result = $db->do($self->{pg_schema}) };
    die "Could not ensure database consistency: " . $db->errstr unless $result;

    $self->{dbh}->{$dbname} = $db;
    return $db;
}

sub _my_dbh {
    my ($self) = @_;
    my $dbname = $self->{dbname};
    return $self->{dbh}->{$dbname} if exists $self->{dbh}->{$dbname};

    my $host = $self->{dbhost} // $ENV{MYSQL_HOST} || 'localhost';
    my $port = $self->{dbport} // $ENV{MYSQL_TCP_PORT} || 3306;
    my $user = $self->{dbuser} // $ENV{DBI_USER};
    my $pass = $self->{dbpass} // $ENV{MYSQL_PWD};

    # Handle the mysql defaults file
    my $defaults_file = $self->{mysql_read_default_file} // "$ENV{HOME}/.my.cnf";
    my $defaults_group = $self->{mysql_read_default_group} // 'client';
    my $df = "";
    $df .= "mysql_read_default_file=$defaults_file;"   if -f $defaults_file;
    $df .= "mysql_read_default_group=$defaults_group;" if $defaults_group;

    my $dsn = "dbi:mysql:mysql_multi_statements=1;database=$dbname;".$df."host=$host;port=$port";

    my $db = DBI->connect($dsn, $user, $pass);
    $db->do($self->{mysql_schema}) or die "Could not ensure database consistency: " . $db->errstr;
    $self->{dbh}->{$dbname} = $db;
    return $db;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

URI::Shortener - Shorten URIs so that you don't have to rely on external services

=head1 VERSION

version 1.004

=head1 SYNOPSIS

    # Actually shortening the URIs
    my $s = URI::Shortener->new(
        domain => 'ACGT',
        prefix => 'https://go.mydomain.test/short',
        dbname => '/opt/myApp/uris.db',
        seed   => 90210,
        length => 12,
    );
    my $uri = 'https://mydomain.test/somePath';
    # Persistently memoizes via sqlite
    my $short = $s->shorten( $uri );
    # Short will look like 'https://go.mydomain.test/short/szAgqIE
    ...
    # Presumption here is that your request router knows what to do with this, e.g. issue a 302:
    my $long = $s->lengthen( $short );
    ...
    # Prune old URIs
    $s->prune_before(time());

=head1 DESCRIPTION

Provides utility methods so that you can:

1) Create a new short uri and store it for usage later

2) Persistently pull it up

3) Store a creation time so you can prune the database later.

We use sqlite for persistence by default with WALmode on, so it should be safe to use in a preforking multiple worker situation.

Alternatively, you can choose to use postgres or mysql.

=head2 WHY?

URI shorteners are typically used for media requiring fixed-width content, such as text email.
Email in particular benefits when you have intermediate servers that alter complex URIs in bodies to "protect" their users.
This tends to make DKIM signed messages fail for predictable reasons.

They are also useful for being easy to say in phonetic alphabets.

On the other hand, they're also an unavoidable mechanism to implement user tracking, such as is commonly done by social networking applications.
Similarly, they are the backbone of many phishing spam campaigns.

You could also use this to build a site (or make portions of it) resistant to indexing due to random URIs.
This is common practice for "unlisted" posts sent by mailing lists which want some degree of exclusivity without resorting fully to a paywall.

=head2 ALGORITHM

The particular algorithm used to generate the ciphertext composing the shortened URI is Crypt::PRNG's 'fortuna'.
This is used to make it very difficult to guess valid shortened URIs.

The seed used is the one passed to the constructor plus the database row ID.
As there is no guarantee of uniform distribution, such as in a Mersenne Twister, sometimes this will fail.
Even were we using such, nobody ever implements nth-guess, which means we have to slog through actual generation which is worse performing than miss/retry in practice.

In such events, we simply burn the ID (leaving it as a dead record) and move on until we succeed.
This is implemented by goto &shorten, which means in the event you run out of possible URIs, you will smash the stack or fill your disk (whichever comes first).

As such we die after failing 64 times to prevent such outcomes.
This is also why a pruning method for old records has been provided.

=head2 IMPORTANT

It must be stressed that choosing a sufficiently large domain and length is important.
Sane defaults are used, but if you choose something lesser, you will have to prune aggressively to prevent bad outcomes.
You are basically "locked in" to your choice of domain/length/seed once you put something based upon this into production.

The difficulty of bruting for valid URIs scales with the size of the domain and length.

You shouldn't store particularly sensitive information in any URI, or attempt to use this as a means of access control.
It only takes one right guess to ruin someone's day.

I strongly recommend that you configure whatever serves these URIs be behind a fail2ban rule that bans 3 or more 4xx responses.

The domain & seed used is not stored in the DB, so don't lose it.
You can't use a DB valid for any other domain/seed and expect anything but GIGO.

Multiple different prefixes for the shortened URIs are OK though.
The more you use, the harder it is to guess valid URIs.
Sometimes, CNAMEs are good for something.

=head2 OTHER CONSEQUENCES

If you prune old DB records and your database engine will then reuse these IDs, be aware that this will result in some old short URIs resolving to new pages.

=head2 UTF-8

I have not tested this module with a UTF8 domain.
My expectation is that it will not work at all with it, but this could be patched straighforwardly.

=head2 OTHER DATABASES

We support use of other databases than sqlite, should you so desire.
Set the dbhost, dbport, dbuser, dbpass and specify an appropriate dbtype (supported: sqlite, pg, mysql).

While we choose to use the largest possible autoincrementing primary key type,
be aware you will be fundamentally limited to the largest integer that can represent.
Mysql's BIGINT in particular is different than Postgres' BIGSERIAL and SQLite's INTEGER.

If the names of the tables/indexes collides with stuff already in your DB, you can pass parameters to the constructor to fix that.
Here are the defaults:

    uri_tablename    => 'uris',
    prefix_tablename => 'prefix',
    uri_idxname      => 'uri_idx',
    prefix_idxname   => 'prefix_idx',
    cipher_idxname   => 'cipher_idx',
    created_idxname  => 'created_idx',

Be aware that this is done via regexp replacement, so if you have too similar of names, bad things will occur.

=head2 MYSQL LIMITATIONS

Due to the nature of mysql's text handling, we don't make the 'uri' or 'prefix' fields in their respective tables unique.
Similarly, the cipher (domain) length is limited to 180 chars, as this is about as big as you can prudently use on utf8mb4.

We also are not creating any indices whatsoever.
Pull requests welcome.

=head1 CONSTRUCTOR

=head2 $class->new(%options)

=over 4

=item C<dbname>

Name of the database to use.  Filename when using sqlite.

=item C<dbtype>

Type of database to use.  Supported: (sqlite, mysql, pg)

=item C<dbhost,dbport,dbuser,dbpass>

Means to connect to remote databases, such as is the case with mysql/pg

dbhost defaults to localhost, and dbport defaults to the relevant default port.
Otherwise the relevant ENV vars are obeyed when no options are passed.

See _my_dbh() and _pg_dbh() for the particulars.

Also, mysql will obey the mysql_read_default_file/group parameters, and defaults to using ~/.my.cnf and the 'client' group.

=item C<prefix>

URI prefix of shortened output.  Trailing slashes will be stripped.  Example: https://big.hugs/go/

=item C<length>

Length of the minified path component. Defaulted to 12 when not a member of the natural numbers.

=item C<domain>

Input domain string. Shortened path components are a char within this string. By default a..zA..Z.

=item C<seed>

Starting seed of the PRNG.

=back

This is obviously an "N Choose K" situation (n possible chars from 'domain' in 'length' slots).
The default number of URIs possible is:

    558,383,307,300

Which I should hope is more than enough for most use cases.

=head1 METHODS

=head2 cipher( INTEGER $id )

Wrapper around Crypt::PRNG::string_from().

Uses the passed seed + id as the seed, and builds string_from via the domain passed to the constructor.

=head2 shorten( STRING $uri)

Transform original URI into a shortened one.

=head2 lengthen( STRING $uri)

Transform shortened URI into it's original.

=head2 prune_before(TIME_T $when)

Remove entries older than UNIX timestamp $when.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/URI-Shorten/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 Troglodyne LLC


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
