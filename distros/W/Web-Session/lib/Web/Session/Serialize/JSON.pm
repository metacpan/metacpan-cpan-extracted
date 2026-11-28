# Directly copied from Lemonldap::NG project (http://lemonldap-ng.org/)
package Web::Session::Serialize::JSON;

use strict;
use JSON;

our $VERSION = '1.0.0';

my $json     = JSON->new->allow_nonref;
my $utf8Json = JSON->new->utf8->allow_nonref;

# Writers produce canonical JSON (keys sorted): Perl randomizes the order of
# hash keys (per process and per hash), so the same data would otherwise be
# serialized differently from one save to the next. SQL stores compare the
# serialized data with the one they read to skip the write of an unchanged
# session (see Web::Session::Store::DBI)
my $canonicalJson = JSON->new->canonical->allow_nonref;
my $latin1Json    = JSON->new->canonical->latin1->allow_nonref;

sub serialize {
    my $session = shift;

    $session->{serialized} = $canonicalJson->encode( $session->{data} );

    # JSON::PP doesn't flag its result as UTF-8 when data holds only Latin-1
    # characters: some DBD drivers would then store Latin-1 bytes
    utf8::upgrade( $session->{serialized} );
    return $session->{serialized};
}

# For stores that can only hold Latin-1 bytes (Redis): characters above U+00FF
# are written as \uXXXX escapes, so the result can always be downgraded
sub serializeLatin1 {
    my $session = shift;

    $session->{serialized} = $latin1Json->encode( $session->{data} );
    return $session->{serialized};
}

sub unserialize {
    my ( $session, $next ) = @_;

    my $data = _unserialize( $session->{serialized}, $next );
    die "Session could not be unserialized" unless defined $data;
    $session->{data} = $data;
}

# For stores that never return UTF-8 bytes (Redis stores Latin-1)
sub unserializeLatin1 {
    my ( $session, $next ) = @_;

    my $data = _unserialize( $session->{serialized}, $next, 1 );
    die "Session could not be unserialized" unless defined $data;
    $session->{data} = $data;
}

sub _unserialize {
    my ( $serialized, $next, $latin1 ) = @_;
    my $tmp;

    # Some stores (MySQL json columns, files,...) return UTF-8 bytes
    if ( defined $serialized and !$latin1 and !utf8::is_utf8($serialized) ) {
        $tmp = eval { $utf8Json->decode($serialized) };
        return $tmp unless ($@);
    }
    eval { $tmp = $json->decode($serialized) };
    if ($@) {
        require Storable;
        $next ||= \&Storable::thaw;
        return &$next($serialized);
    }
    return $tmp;
}

1;

=pod

=head1 NAME

=encoding utf8

Web::Session::Serialize::JSON - Use JSON to zip up data

=head1 SYNOPSIS

 use Web::Session::Serialize::JSON;

 $zipped = Web::Session::Serialize::JSON::serialize($ref);
 $ref = Web::Session::Serialize::JSON::unserialize($zipped);

=head1 DESCRIPTION

This module fulfills the serialization interface of Apache::Session.
It serializes the data in the session object by use of L<JSON>. The
serialized data is UTF-8 text.

The output is canonical: object keys are sorted, so the same data always gives
the same string, whatever the order in which Perl stores the hash keys. SQL
backends rely on it to skip the rewrite of an unchanged session (see
L<Web::Session/"UNCHANGED SESSIONS ARE NOT REWRITTEN">).

When reading, a string returned as bytes by the store (not flagged as UTF-8,
for example a MySQL C<json> column) is first decoded as UTF-8 JSON; if it is
not valid UTF-8, it is read as characters.

Some stores return Latin-1 bytes instead: SQLite without C<sqlite_unicode>,
and MySQL C<json> or C<text> columns holding data written by an old node
using JSON::PP. A Latin-1 session that is also valid UTF-8 is then read as
UTF-8: for example "Ã©" becomes "é". This needs every non-ASCII character of
the session to be part of such a sequence, that is bytes C2-DF followed by
80-BF, or a valid UTF-8 sequence formed over the whole session (mostly values
that are already mojibake).
How strictly "valid UTF-8" is checked depends on the JSON backend: JSON::XS
accepts surrogates, code points above U+10FFFF and 5-byte sequences, unlike
JSON::PP and Cpanel::JSON::XS. The rare Latin-1 byte strings misread as UTF-8
therefore vary slightly between backends.

File and Redis are not affected: Redis stores Latin-1 but reads it with
C<unserializeLatin1()>, which skips the UTF-8 decode, and
L<Web::Session::Store::File> always writes UTF-8. Files written
by an older version keep their ambiguity: Latin-1 bytes that also form a valid
UTF-8 sequence can't be told apart from UTF-8 ones.

=head1 UPGRADE

Previous versions read UTF-8 bytes returned by the store as Latin-1. With
JSON::XS the serialized data is unchanged, so they still read sessions as
they did before. With JSON::PP the added C<utf8::upgrade()> changes the
bytes stored by the DBD-based backends (a Latin-1 string becomes UTF-8), so
an old node reading a session written by a new one sees mojibake. Files are
affected the same way: they are now always written as UTF-8, where older
versions stored Latin-1 bytes for a session holding only Latin-1 characters.
A session
rewritten by a previous version during a rolling upgrade keeps the
double-encoded values it read, and sessions already corrupted this way are
not repaired. Upgrade all servers sharing sessions (for Lemonldap::NG, all
portals and handlers) together.

Redis clients refuse characters above U+00FF. Redis therefore writes sessions
with C<serializeLatin1()>: characters above U+00FF (surrogate pairs above
U+FFFF) are escaped as C<\uXXXX> and the others are kept, so the result can
always be downgraded to Latin-1 bytes. For a session holding only Latin-1
characters, it is the same string as C<serialize()>. C<unserialize()> reads
the escapes back as the original characters.

=head1 SEE ALSO

L<JSON>, L<Apache::Session>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 COPYRIGHT AND LICENSE

=over

=item 2009-2026 by Xavier Guimard

=item 2013-2025 by Clément Oudot

=item 2019-2025 by Maxime Besson

=item 2013-2025 by Worteks

=item 2023-2026 by Linagora

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
