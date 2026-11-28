package Web::Session::MariaDBJSON;

use strict;

use Apache::Session::Lock::Null;
use Web::Session::Store::MariaDBJSON;
use Web::Session::Generate::SHA256;
use Web::Session::Serialize::JSON;
use Web::Session::MySQLJSON;
use Web::Session::_common;

our $VERSION = '1.0.0';
our @ISA     = qw(Web::Session::MySQLJSON);

sub populate {
    my $self = shift;

    $self->{object_store} =
      new Web::Session::Store::MariaDBJSON $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Web::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Web::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Web::Session::Serialize::JSON::serialize;
    $self->{unserialize}  = \&Web::Session::Serialize::JSON::unserialize;

    return $self;
}

# DBD::mysql needs mysql_enable_utf8mb4 at connection time to exchange UTF-8
# (see the Store)
sub _classDbh {
    my ( $class, $args ) = @_;

    my $datasource = $args->{DataSource} or die "No datasource given !";
    return DBI->connect_cached(
        $datasource,
        $args->{UserName},
        $args->{Password},
        Web::Session::_common->_forkSafeAttr(
            Web::Session::Store::MariaDBJSON->connectAttributes($datasource)
        )
    ) || die $DBI::errstr;
}

# Indexed fields are read from the generated column of the same name: MariaDB
# doesn't always use the index of a generated column when a query contains
# its expression. Fields whose column is not usable are read from the JSON
# document like the other ones
sub _sqlField {
    my ( $class, $dbh, $field, $args ) = @_;
    if ( $class->_useColumn( $dbh, $field, $args ) ) {
        my ($f) = $class->_utf8($field);
        $f =~ s/`/``/g;
        return "`$f`";
    }
    return 'JSON_VALUE(a_session, ' . $class->_sqlPath( $dbh, $field ) . ')';
}

# True if $field is listed in Index and has a usable generated column
sub _useColumn {
    my ( $class, $dbh, $field, $args ) = @_;
    return 0 unless ( $args and $class->_fieldIsIndexed( $args, $field ) );
    my $valid = $class->_checkIndex( $dbh, $args ) or return 0;
    my ($f) = $class->_utf8($field);
    return $valid->{$f} ? 1 : 0;
}

# Indexed fields are read from a generated column: a column that exists but
# is not generated (for example left over from a migration from
# the former column-based MySQL backend, where the store wrote real columns) stays NULL. Check
# the columns once per handle, table and Index list. Returns the hash
# reference of the fields that can be read from their column (empty without
# database handle)
sub _checkIndex {
    my ( $class, $dbh, $args ) = @_;
    return {} unless ($dbh);
    my $index =
      ref( $args->{Index} ) ? $args->{Index} : [ split /\s+/, $args->{Index} ];
    my @index = $class->_utf8( grep { defined and length } @$index );
    return {} unless (@index);

    my $table = $args->{TableName} || $Apache::Session::Store::DBI::TableName;

    # DBI only keeps private_* attributes
    my $checked = $dbh->{private_asb_mariadbjson_index} ||= {};
    my $key = join "\0", $table, @index;
    return $checked->{$key} if ( $checked->{$key} );

    # TableName may be "schema.table", with or without backquotes
    my ( $schema, $name ) = ( undef, $table );
    if ( $table =~ /^`?([^`.]+)`?\.`?([^`.]+)`?\z/ ) {
        ( $schema, $name ) = ( $1, $2 );
    }
    else {
        $name =~ s/`//g;
    }

    my $sth = $dbh->prepare(
        'SELECT COLUMN_NAME, GENERATION_EXPRESSION'
          . ' FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = '
          . ( defined $schema ? '?' : 'DATABASE()' )
          . ' AND TABLE_NAME = ? AND COLUMN_NAME IN ('
          . join( ',', ('?') x @index ) . ')' );
    $sth->execute( ( defined $schema ? $schema : () ), $name, @index );
    my %expr = map { $_->[0] => $_->[1] } @{ $sth->fetchall_arrayref };
    $sth->finish;

    my ( %valid, @unusable );
    foreach my $field (@index) {
        if ( defined( $expr{$field} ) and $expr{$field} =~ /\ba_session\b/ ) {
            $valid{$field} = 1;
            next;
        }
        my $why = exists( $expr{$field} )
          ? 'it exists but is not generated from a_session'
          : 'there is no column with this name';
        push @unusable, "\"$field\" ($why)";
    }
    $checked->{$key} = \%valid;

    # Warn rather than die: the lookup compares names between Perl and
    # information_schema, which can fail on an exotic name encoding even when
    # the column is fine
    warn "Web::Session::MariaDBJSON: unusable Index field(s) in"
      . " table $table: "
      . join( ', ', @unusable )
      . ". They are read from the JSON document, which is slower; add a"
      . " generated column based on a_session (see the documentation)\n"
      if (@unusable);
    return \%valid;
}

# No CAST for indexed fields: it would prevent the use of the index
sub _buildCompareExpression {
    my ( $class, $field, $op, $value, $dbh, $args ) = @_;
    $class->_checkOp($op);
    return $class->_sqlField( $dbh, $field, $args ) . " $op $value"
      if ( $class->_useColumn( $dbh, $field, $args ) );
    return $class->SUPER::_buildCompareExpression( $field, $op, $value, $dbh );
}

1;
__END__

=head1 NAME

Web::Session::MariaDBJSON - Add index and search methods to
Apache::Session::MySQL for MariaDB, using a JSON field

=head1 SYNOPSIS

Create table. Example for Lemonldap::NG with generated columns and indexes:

  CREATE TABLE sessions (
      id varchar(64) not null primary key,
      a_session json,
      _whatToTrace varchar(255) COLLATE utf8mb4_bin
          AS (JSON_VALUE(a_session, '$._whatToTrace')) VIRTUAL,
      _session_kind varchar(32) COLLATE utf8mb4_bin
          AS (JSON_VALUE(a_session, '$._session_kind')) VIRTUAL,
      _utime bigint unsigned
          AS (cast(JSON_VALUE(a_session, '$._utime') as unsigned)) VIRTUAL,
      _lastSeen bigint unsigned
          AS (cast(JSON_VALUE(a_session, '$._lastSeen') as unsigned)) VIRTUAL,
      _oidcRtUpdate bigint unsigned
          AS (cast(JSON_VALUE(a_session, '$._oidcRtUpdate') as unsigned))
          VIRTUAL,
      ipAddr varchar(64) COLLATE utf8mb4_bin
          AS (JSON_VALUE(a_session, '$.ipAddr')) VIRTUAL,
      KEY _whatToTrace (_whatToTrace),
      KEY _session_kind (_session_kind),
      KEY _utime (_utime),
      KEY _lastSeen (_lastSeen),
      KEY _oidcRtUpdate (_oidcRtUpdate),
      KEY ipAddr (ipAddr)
  ) ENGINE=InnoDB;

In MariaDB, C<json> is an alias for C<longtext COLLATE utf8mb4_bin
CHECK (json_valid(a_session))>.

Use it with Perl:

  use Web::Session::MariaDBJSON;

  my $args = {
       DataSource => 'dbi:MariaDB:database=sessions', # or dbi:mysql:...
       UserName   => $db_user,
       Password   => $db_pass,

       # Fields that have a generated column
       Index      => '_whatToTrace _session_kind _utime _lastSeen'
                   . ' _oidcRtUpdate ipAddr',
  };

The DSN selects the driver: C<dbi:MariaDB:...> requires DBD::MariaDB and
C<dbi:mysql:...> requires DBD::mysql, otherwise DBI dies with
C<install_driver(...) failed>. DBD::MariaDB always exchanges UTF-8 (utf8mb4).
With DBD::mysql, this module connects with C<mysql_enable_utf8mb4>, which
selects utf8mb4 for the connection (characters outside the BMP, such as
emoji, are supported). When you give your own C<Handle> to the store, it is
used as is: connect it with C<mysql_enable_utf8mb4> (or C<SET NAMES utf8mb4>).

Use it like L<Web::Session::MySQLJSON>.
L<Web::Session::MariaDB> is an alias of this module.

=head2 Generated columns

Any field can be searched, but only the fields listed in C<Index> can use an
index. Each of them must have a generated column (C<VIRTUAL> or
C<PERSISTENT>) with an index. Rules:

=over

=item *

The column name must be exactly the field name: this module queries
the column itself because MariaDB doesn't reliably use the index of a
generated column when a query contains its expression (10.11 never does,
11.8 never does for C<LIKE>).

=item *

Columns must be generated from C<a_session>: this module writes only
C<id> and C<a_session>.

=item *

A column listed in C<Index> that exists but is not generated from
C<a_session> - for example one left over from a migration from
the former column-based C<Web::Session::MySQL>, which wrote
real columns - stays NULL.
This module checks C<Index> once per database handle, warns about such fields
(and about missing columns) and reads them from the JSON document like fields
that are not listed in C<Index>: results are the same, only slower.

=item *

C<VIRTUAL> columns are computed when read and use no space in the table
(their index does). C<PERSISTENT> columns are stored: they use more space but
are not recomputed.

=item *

Text columns must use the C<utf8mb4_bin> collation, as in the example above:
otherwise indexed fields follow the table collation (by default,
case-insensitive, and also accent-insensitive with MariaDB 11) whereas other
fields are compared exactly.

=item *

C<_utime>, C<_lastSeen>, C<_oidcRtUpdate> (and other indexed fields used by
deleteIfLowerThan(), searchLt() or searchGt()) must be integer columns: these
methods compare the column directly (they cast other fields to C<unsigned>).

=item *

With strict SQL mode, a value that doesn't fit into its column (too
long string, non-integer C<_utime>, C<_lastSeen> or C<_oidcRtUpdate>) makes
the session storage fail: size C<varchar> columns generously; Lemonldap::NG
always writes integer C<_utime>, C<_lastSeen> and C<_oidcRtUpdate>.

=back

C<_lastSeen> is needed when Lemonldap::NG "timeoutActivity" is used: sessions
purge then deletes sessions whose C<_utime> B<or> C<_lastSeen> is too old,
and an C<OR> with a non indexed side forces a full table scan (with both
columns, MariaDB uses an C<index_merge>).

C<_oidcRtUpdate> is useful when OpenID Connect relying parties have a refresh
token activity timeout: sessions purge then calls searchLt() on
C<_oidcRtUpdate>.

Fields that are not listed in C<Index> are read with
C<JSON_VALUE(a_session, '$.field')>. C<JSON_VALUE> returns C<NULL> for missing
fields, JSON C<null>, arrays and objects: such values can't be searched and
get_key_from_all_sessions() returns C<undef> for them when called with field
names.

Searches are exact (case- and accent-sensitive) for all fields, as long as
generated text columns use the C<utf8mb4_bin> collation (see above). Field
names and searched values are strings: a non flagged string containing bytes
C<0x80> or more is first tried as UTF-8 and read as Latin-1 if it is not
valid UTF-8, so both encodings find non-ASCII values.

To add a generated column to an existing table:

  ALTER TABLE sessions
      ADD COLUMN ipAddr varchar(64) COLLATE utf8mb4_bin
          AS (JSON_VALUE(a_session, '$.ipAddr')) VIRTUAL,
      ADD KEY ipAddr (ipAddr);

=head1 DESCRIPTION

Web::Session provides some class methods to manipulate all
sessions and add the capability to index some fields to make research faster.

Web::Session::MariaDBJSON implements it for MariaDB databases,
storing sessions in JSON and using generated columns for indexed fields. It
works with DBD::MariaDB (C<dbi:MariaDB:...>) and DBD::mysql
(C<dbi:mysql:...>). It has been tested with MariaDB 10.11 and 11.8.

For MySQL, use L<Web::Session::MySQLJSON>.

=head2 searchLt() and searchGt()

  # Sessions whose _utime is lower than $time
  my $hash = Web::Session::MariaDBJSON->searchLt( $args,
      '_utime', $time, 'uid' );

searchLt() and searchGt() take the same arguments and return the same data as
searchOn(): sessions whose field is lower (or greater) than the given value,
which is excluded. The value must be a number (C<12>, C<-12> or C<12.5>):
otherwise nothing is returned and an error is printed on STDERR. Spaces
around the value are ignored.

Fields are compared in SQL as deleteIfLowerThan() does: fields listed in
C<Index> on their (integer) generated column, which index is used (only if
the Index check accepted this column, see above), other fields with C<cast(JSON_VALUE(a_session, '$.field') as unsigned)>. Values are
compared as unsigned integers: a non-numeric value is 0.

Sessions without the field are never returned. This differs from the Perl
fallback of Lemonldap::NG, where a missing field is compared as 0: searchLt()
would then return nearly all sessions. Lemonldap::NG doesn't need them: its
sessions purge ignores sessions without C<_oidcRtUpdate>. A field stored as
JSON C<null> is skipped too (C<JSON_VALUE> returns C<NULL>).

For fields not listed in C<Index>, a negative value becomes a huge number
because of the unsigned cast (C<-5> is found by
C<searchGt( $args, $field, 50 )>). Lemonldap::NG timestamps are positive
integers.

=head1 SEE ALSO

L<Apache::Session>, L<Web::Session::MySQLJSON>, L<http://lemonldap-ng.org>

=head1 COPYRIGHT AND LICENSE

=encoding utf8

=over

=item 2009-2026 by Xavier Guimard

=item 2013-2025 by Clément Oudot

=item 2019-2025 by Maxime Besson

=item 2013-2025 by Worteks

=item 2023-2026 by Linagora

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
