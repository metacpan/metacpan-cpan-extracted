package URI::Shortener 1.001;

#ABSTRACT: Shorten URIs so that you don't have to rely on external services

use strict;
use warnings;

use v5.012;

use Carp::Always;
use POSIX qw{floor};
use DBI;
use DBD::SQLite;
use File::Touch;
use Crypt::PRNG;


our $SCHEMA = qq{
CREATE TABLE IF NOT EXISTS uris (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    prefix_id INTEGER NOT NULL REFERENCES prefix(id) ON DELETE CASCADE,
    uri TEXT NOT NULL UNIQUE,
    cipher TEXT DEFAULT NULL UNIQUE,
    created INTEGER
);

CREATE TABLE IF NOT EXISTS prefix (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    prefix TEXT NOT NULL UNIQUE
);

CREATE INDEX IF NOT EXISTS uri_idx     ON uris(uri);
CREATE INDEX IF NOT EXISTS prefix_idx  ON prefix(prefix);
CREATE INDEX IF NOT EXISTS cipher_idx  ON uris(cipher);
CREATE INDEX IF NOT EXISTS created_idx ON uris(created);
};


sub new {
    my ( $class, %options ) = @_;
    $options{domain} ||= join('',('a'..'z','A'..'Z'));

    foreach my $required (qw{domain prefix dbname seed}) {
        die "$required required" unless $options{$required};
    }
    $options{length} = 12 if !$options{length} || $options{length} < 0;

    # Strip trailing slash from prefix
    $options{prefix} =~ s|/+$||;
    return bless( \%options, $class );
}


sub cipher {
    my ( $self, $id ) = @_;
    my $rr = Crypt::PRNG->new('Fortuna', $self->{seed} + $id);
    return $rr->string_from($self->{domain}, $self->{length});
}


# Like with any substitution cipher, reversal is trivial when the domain is known.
# But, if we have to fetch the URI anyways, we may as well just store the cipher for reversal (aka the "god algorithm").
# This allows us the useful feature of being able to use many URI prefixes.
my $smash=0;
sub shorten {
    my ( $self, $uri ) = @_;

    my $query = "SELECT id, cipher FROM uris WHERE uri=?";

    my $rows = $self->_dbh()->selectall_arrayref( $query, { Slice => {} }, $uri );
    $rows //= [];
    if (@$rows) {
        return $self->{prefix}."/".$rows->[0]{cipher} if $rows->[0]{cipher};
        my $ciphered = $self->cipher( $rows->[0]{id} );
        my $worked = $self->_dbh()->do( "UPDATE uris SET cipher=? WHERE id=?", undef, $ciphered, $rows->[0]{id} );
        # In the (incredibly rare) event of a collision, just burn the row and move on.
        if (!$worked) {
            warn "DANGER: cipher collision detected.";
            $self->_dbh()->do( "UPDATE uris SET uri=? WHERE id=?", undef, "$uri-BURNED$smash", $rows->[0]{id} ) or die "Could not burn row";
            $smash++;
            die "Too many failures to avoid name collisions encountered, prune your DB!" if $smash > 64;
            goto \&shorten;
        }
        return $self->{prefix} . "/" . $ciphered;
    }

    # Otherwise we need to store the URI and retrieve the ID.
    my $pis        = "SELECT id FROM prefix WHERE prefix=?";
    my $has_prefix = $self->_dbh->selectall_arrayref( $pis, { Slice => {} }, $self->{prefix} );
    unless (@$has_prefix) {
        $self->_dbh()->do( "INSERT INTO prefix (prefix) VALUES (?)", undef, $self->{prefix} ) or die $self->_dbh()->errstr;
    }

    my $qq = "INSERT INTO uris (uri,created,prefix_id) VALUES (?,?,(SELECT id FROM prefix WHERE prefix=?))";
    $self->_dbh()->do( $qq, undef, $uri, time(), $self->{prefix} ) or die $self->dbh()->errstr;
    goto \&shorten;
}


sub lengthen {
    my ( $self, $uri ) = @_;
    my ($cipher) = $uri =~ m|^\Q$self->{prefix}\E/(.*)$|;

    my $query = "SELECT uri FROM uris WHERE cipher=? AND prefix_id IN (SELECT id FROM prefix WHERE prefix=?)";

    my $rows = $self->_dbh()->selectall_arrayref( $query, { Slice => {} }, $cipher, $self->{prefix} );
    $rows //= [];
    return unless @$rows;
    return $rows->[0]{uri};
}


sub prune_before {
    my ( $self, $when ) = @_;
    $self->_dbh()->do( "DELETE FROM uris WHERE created < ?", undef, $when ) or die $self->dbh()->errstr;
    return 1;
}

my $dbh = {};

sub _dbh {
    my ($self) = @_;
    my $dbname = $self->{dbname};
    return $dbh->{$dbname} if exists $dbh->{$dbname};

    # Some systems splash down without this.  YMMV.
    File::Touch::touch($dbname) if $dbname ne ':memory:' && !-f $dbname;

    my $db = DBI->connect( "dbi:SQLite:dbname=$dbname", "", "" );
    $db->{sqlite_allow_multiple_statements} = 1;
    $db->do($SCHEMA) or die "Could not ensure database consistency: " . $db->errstr;
    $db->{sqlite_allow_multiple_statements} = 0;
    $dbh->{$dbname} = $db;

    # Turn on fkeys
    $db->do("PRAGMA foreign_keys = ON") or die "Could not enable foreign keys";

    # Turn on WALmode, performance
    $db->do("PRAGMA journal_mode = WAL") or die "Could not enable WAL mode";

    return $db;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

URI::Shortener - Shorten URIs so that you don't have to rely on external services

=head1 VERSION

version 1.001

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

We use sqlite for persistence.

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

=head1 CONSTRUCTOR

=head2 $class->new(%options)

See SYNOPSIS for supported options.

We strip trailing slash(es) from the prefix.

The 'dbfile' you pass will be created automatically for you if possible.
Otherwise we will croak the first time you run shorten() or lengthen().

length controls the length of the minified path component.
Defaulted to 12 when not a member of the natural numbers.

domain is by default a..zA..Z as a string.

This is obviously an n Choose k situation, which means the default number of URIs possible is:

558,383,307,300

Which I should hope is more than enough for most use cases.

=head1 METHODS

=head2 cipher( INTEGER $id )

Wrapper around Crypt::PRNG::string_from().

Uses the passed seed + id as the seed, and builds string_from via the domain passed to the constructor.

=head2 shorten($uri)

Transform original URI into a shortened one.

=head2 lengthen($uri)

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

Copyright (c) 2022 Troglodyne LLC


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
