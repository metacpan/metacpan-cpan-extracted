package Web::Session::MySQLJSON;

use strict;

use Encode;
use Apache::Session;
use Apache::Session::Lock::Null;
use Web::Session::Store::MySQL;
use Web::Session::Generate::SHA256;
use Web::Session::Serialize::JSON;
use Web::Session::DBI;
use Web::Session::_common;

our $VERSION = '1.0.0';
our @ISA     = qw(Web::Session::DBI Apache::Session);

sub populate {
    my $self = shift;

    # Any field can be searched from a_session: setting Index would make the
    # store write the indexed fields into columns of the same name, which
    # don't exist in a JSON table
    if ( $self and $self->{args} and defined $self->{args}->{Index} ) {
        my $index =
          ref( $self->{args}->{Index} )
          ? $self->{args}->{Index}
          : [ split /\s+/, $self->{args}->{Index} ];
        warn "Web::Session::MySQLJSON: Index should not be set,"
          . " the store would write the fields as columns\n"
          if (@$index);
    }

    $self->{object_store} = new Web::Session::Store::MySQL $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Web::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Web::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Web::Session::Serialize::JSON::serialize;
    $self->{unserialize}  = \&Web::Session::Serialize::JSON::unserialize;

    return $self;
}

sub searchOn {
    my ( $class, $args, $selectField, $value, @fields ) = @_;
    my $dbh   = $class->_classDbh($args);
    my $query = {
        query  => $class->_sqlField( $dbh, $selectField, $args ) . ' =?',
        values => [$value]
    };
    return $class->_query( $args, $query, @fields );
}

sub searchOnExpr {
    my ( $class, $args, $selectField, $value, @fields ) = @_;
    my $dbh = $class->_classDbh($args);
    $value =~ s/\*/%/g;
    my $query = {
        query  => $class->_sqlField( $dbh, $selectField, $args ) . ' like ?',
        values => [$value]
    };
    return $class->_query( $args, $query, @fields );
}

# searchLt() and searchGt() are inherited from DBI.pm: any field can be
# compared in SQL here
sub _searchCompare {
    my ( $class, $op, $args, $selectField, $value, @fields ) = @_;
    $value = $class->_checkSearchValue( $op, $value );
    return {} unless ( defined $value );
    return $class->_searchQuery(
        $op,
        sub {
            my $query = {
                query => $class->_buildCompareExpression(
                    $selectField, $op, $value, $class->_classDbh($args), $args
                ),
                values => []
            };
            $class->_query( $args, $query, @fields );
        },
        sub {
            $class->_searchByTest( $args, $selectField,
                $class->_compareTest( $op, $value ), @fields );
        }
    );
}

sub _query {
    my ( $class, $args, $query, @fields ) = @_;
    my %res = ();
    my $index =
      ref( $args->{Index} )
      ? $args->{Index}
      : [ split /\s+/, $args->{Index} ];

    my $dbh        = $class->_classDbh($args);
    my $table_name = $class->_tableName( $dbh, $args );

    my $sth;
    my ( $select, $aliases ) = $class->_sqlSelect( $dbh, \@fields, $args );
    my $fields = @fields ? join( ',', 'id', @$select ) : 'id,a_session';
    $sth =
      $dbh->prepare("SELECT $fields from $table_name where $query->{query}");
    $sth->execute( $class->_utf8( @{ $query->{values} } ) );

    my $res = $sth->fetchall_hashref('id') or return {};
    if (@fields) {
        $class->_renameAliases( $res, $aliases );
    }
    else {
        my $sub = $class->_unserializer;
        foreach my $s ( keys %$res ) {
            eval {
                my $tmp = &$sub( { serialized => $res->{$s}->{a_session} } );
                $res->{$s} = $tmp;
            };
            if ($@) {
                print STDERR "Error in session $s: $@\n";
                delete $res->{$s};
            }
        }
    }
    return $res;
}

sub deleteIfLowerThan {
    my ( $class, $args, $rule ) = @_;
    return wantarray ? ( 0, 0 ) : 0
      unless ( $class->_checkRule($rule) and $class->_checkThresholds($rule) );
    my ( $query, @bind );
    my $dbh = eval { $class->_classDbh($args) };
    unless ($dbh) {
        print STDERR "deleteIfLowerThan: $@\n";
        return wantarray ? ( 0, 0 ) : 0;
    }
    if ( $rule->{or} ) {
        $query = join ' OR ', map {
            $class->_buildLowerThanExpression( $_, $rule->{or}->{$_}, $dbh, $args )
          }
          keys %{ $rule->{or} };
    }
    elsif ( $rule->{and} ) {
        $query = join ' AND ', map {
            $class->_buildLowerThanExpression( $_, $rule->{and}->{$_}, $dbh, $args )
          }
          keys %{ $rule->{and} };
    }
    return wantarray ? ( 0, 0 ) : 0 unless ($query);
    if ( $rule->{not} and keys %{ $rule->{not} } ) {
        $query = "($query) AND " . join(
            ' AND ',
            map {
                push @bind, $rule->{not}->{$_};
                my $f = $class->_sqlField( $dbh, $_, $args );
                "($f IS NULL OR $f <> ?)"
              }
              keys %{ $rule->{not} }
        );
    }
    my $table_name = $class->_tableName( $dbh, $args );
    my $rows =
      eval { $dbh->do( "DELETE FROM $table_name WHERE $query", undef,
            $class->_utf8(@bind) ) };
    if ($@) {
        print STDERR "deleteIfLowerThan: $@\n";
        return wantarray ? ( 0, 0 ) : 0;
    }
    return wantarray ? ( 0, 0 ) : 0 unless defined $rows;

    if (wantarray) {
        $rows = 0 if $rows == -1;
        return ( 1, $rows );
    }
    else {
        return 1;
    }
}

sub get_key_from_all_sessions {
    my ( $class, $args, $data ) = @_;

    my $dbh        = $class->_classDbh($args);
    my $table_name = $class->_tableName( $dbh, $args );
    my $sth;

    # Special case if all wanted fields are indexed
    if ( $data and ref($data) ne 'CODE' ) {
        $data = [$data] unless ( ref($data) );
        my ( $select, $aliases ) = $class->_sqlSelect( $dbh, $data, $args );
        my $fields = join ',', 'id', @$select;
        $sth = $dbh->prepare("SELECT $fields from $table_name");
        $sth->execute;
        my $res = $sth->fetchall_hashref('id');
        $class->_renameAliases( $res, $aliases );
        return $res;
    }
    my %res;
    my $sub = $class->_unserializer;
    $class->_forEachSession(
        $dbh,
        $table_name,
        sub {
            my @row = @_;
            eval {
                my $tmp = &$sub( { serialized => $row[1] } );
                if ( ref($data) eq 'CODE' ) {
                    $tmp = &$data( $tmp, $row[0] );
                    $res{ $row[0] } = $tmp if ( defined($tmp) );
                }
                elsif ($data) {
                    $data = [$data] unless ( ref($data) );
                    $res{ $row[0] }->{$_} = $tmp->{$_} foreach (@$data);
                }
                else {
                    $res{ $row[0] } = $tmp;
                }
            };
            if ($@) {
                print STDERR "Error in session $row[0]: $@\n";
                delete $res{ $row[0] };
            }
        }
    );
    return \%res;
}

# Same arguments as in DBI.pm plus the database handle (needed to quote the
# JSON path) and connection arguments. The handle is optional: without one,
# _sqlPath() quotes the path. The expression must match the documented
# generated columns
sub _buildCompareExpression {
    my ( $class, $field, $op, $value, $dbh, $args ) = @_;
    $class->_checkOp($op);
    my $f = $class->_sqlField( $dbh, $field, $args );
    return "cast($f as UNSIGNED) $op $value";
}

# Build SQL expression to get a field from a_session ($args: connection
# arguments, for subclasses)
sub _sqlField {
    my ( $class, $dbh, $field, $args ) = @_;
    return 'a_session->>' . $class->_sqlPath( $dbh, $field );
}

# Build the SQL literal of the JSON path of a field. Field name is used as
# JSON path member, quoted if needed. The database handle is only used to
# quote the path: it may be missing on the DBI deleteIfLowerThan() path
sub _sqlPath {
    my ( $class, $dbh, $field ) = @_;
    my $path;
    if ( $field =~ /^[A-Za-z_][A-Za-z0-9_]*\z/ ) {
        $path = "\$.$field";
    }
    else {
        ( my $f = $field ) =~ s/(["\\])/\\$1/g;
        $path = qq{\$."$f"};
    }
    ($path) = $class->_utf8($path);
    return $dbh->quote($path) if ( defined $dbh );

    # No database handle: quote the path here (MySQL escapes backslashes)
    $path =~ s/\\/\\\\/g;
    $path =~ s/'/''/g;
    return "'$path'";
}

# DBD::mysql sends strings as stored by Perl: store them in UTF-8 so that
# characters U+0080 to U+00FF are not sent in Latin-1. A non flagged string
# containing bytes >= 0x80 may be UTF-8 or Latin-1 encoded: try UTF-8 first
# (strictly), and fall back to Latin-1 (utf8::upgrade) only if it is not
# valid UTF-8
sub _utf8 {
    my $class = shift;
    return map {
        my $s = $_;
        if (   defined($s)
            and !utf8::is_utf8($s)
            and $s =~ /[\x80-\xff]/ )
        {
            my $decoded =
              eval { Encode::decode( 'UTF-8', $s, Encode::FB_CROAK ) };
            if ( defined($decoded) ) { $s = $decoded }
            else                     { utf8::upgrade($s) }
        }
        $s
    } @_;
}

# Build the SELECT list for the given fields. Column aliases are generated
# (a field name may contain "?", which DBD::mysql takes for a placeholder even
# inside backquotes): returns the list and an alias => field name hash
sub _sqlSelect {
    my ( $class, $dbh, $fields, $args ) = @_;
    my ( @select, %aliases );
    foreach my $field (@$fields) {
        my $alias = 'f' . scalar(@select);
        $aliases{$alias} = $field;
        push @select, $class->_sqlField( $dbh, $field, $args ) . " AS `$alias`";
    }
    return ( \@select, \%aliases );
}

# Replace generated aliases by field names in results
sub _renameAliases {
    my ( $class, $res, $aliases ) = @_;
    return unless ( $res and %$aliases );
    foreach my $row ( values %$res ) {
        %$row = (
            ( map { $aliases->{$_} => $row->{$_} } keys %$aliases ),
            id => $row->{id}
        );
    }
}

sub _classDbh {
    my ( $class, $args ) = @_;

    my $datasource = $args->{DataSource} or die "No datasource given !";
    my $username   = $args->{UserName};
    my $password   = $args->{Password};
    my $dbh =
      DBI->connect_cached( $datasource, $username, $password,
        Web::Session::_common->_forkSafeAttr(
            { RaiseError => 1, AutoCommit => 1 }
        )
      )
      || die $DBI::errstr;

    # DBD::MariaDB always uses UTF-8
    $dbh->{mysql_enable_utf8} = 1 if ( $dbh->{Driver}->{Name} eq 'mysql' );
    return $dbh;
}

1;
__END__

=head1 NAME

Web::Session::MySQLJSON - Add index and search methods to
Apache::Session::MySQL

=head1 SYNOPSIS

Create table. Example for Lemonldap::NG with optional generated columns and
indexes:

  CREATE TABLE sessions (
      id varchar(64) not null primary key,
      a_session json,
      as_wt varchar(255) COLLATE utf8mb4_bin
          AS (a_session->>'$._whatToTrace') VIRTUAL,
      as_sk varchar(32) COLLATE utf8mb4_bin
          AS (a_session->>'$._session_kind') VIRTUAL,
      as_ut bigint unsigned
          AS (cast(a_session->>'$._utime' as unsigned)) VIRTUAL,
      as_ls bigint unsigned
          AS (cast(a_session->>'$._lastSeen' as unsigned)) VIRTUAL,
      as_rt bigint unsigned
          AS (cast(a_session->>'$._oidcRtUpdate' as unsigned)) VIRTUAL,
      as_ip varchar(64) COLLATE utf8mb4_bin
          AS (a_session->>'$.ipAddr') VIRTUAL,
      KEY as_wt (as_wt),
      KEY as_sk (as_sk),
      KEY as_ut (as_ut),
      KEY as_ls (as_ls),
      KEY as_rt (as_rt),
      KEY as_ip (as_ip)
  ) ENGINE=InnoDB;

MySQL uses the index of a generated column only when the query contains the
same expression, so keep these expressions exactly as written: they are the
ones used by this module (C<-E<gt>E<gt>> returns unquoted values whereas
C<-E<gt>> keeps JSON quotes). MySQL doesn't use them for C<LIKE> queries, so
searchOnExpr() always scans the table.

Searches are exact (case and accent sensitive). Generated text columns must
use the C<utf8mb4_bin> collation: otherwise, searches on indexed fields follow
the table collation (case and accent insensitive with C<utf8mb4_0900_ai_ci>,
the default of MySQL 8) whereas searches on other fields don't.

Exception: C<utf8mb4_bin> is a C<PAD SPACE> collation, so C<=> ignores
trailing spaces: an indexed search for C<'dwho '> finds the sessions of
C<dwho>, whereas a search on a non indexed field (done by Perl) doesn't. To
avoid it, use a C<NO PAD> collation: C<utf8mb4_0900_bin> on MySQL E<gt>=
8.0.17 (C<utf8mb4_nopad_bin> on MariaDB).

C<as_ls> is needed when Lemonldap::NG "timeoutActivity" is used: sessions purge
then deletes sessions whose C<_utime> B<or> C<_lastSeen> is too old, and an
C<OR> with a non indexed side forces a full table scan (with both keys, MySQL
uses an C<index_merge>).

C<as_rt> is useful when OpenID Connect relying parties have a refresh token
activity timeout: sessions purge then calls searchLt() on C<_oidcRtUpdate>.

With strict SQL mode (default since MySQL 5.7), a value that doesn't fit its
indexed generated column makes the session storage fail: a string longer than
the column, or a non integer C<_utime>, C<_lastSeen> or C<_oidcRtUpdate> value
(C<cast('1.5' as unsigned)> is an error in this case). Size C<varchar> columns
generously; Lemonldap::NG always writes integer C<_utime>, C<_lastSeen> and
C<_oidcRtUpdate>.
These values must be non negative integers: a JSON C<null> (for example
C<_lastSeen =E<gt> undef>) or a negative number is refused too, since
C<-E<gt>E<gt>> returns the string C<'null'> (not SQL C<NULL>) and the session
can't be written anymore. An absent key is fine (the column is C<NULL>).

Generated columns documented by previous versions (using C<-E<gt>>) were
never used. To fix an existing table, drop those you created:

  ALTER TABLE sessions DROP COLUMN as_wt, DROP COLUMN as_sk,
      DROP COLUMN as_ut, DROP COLUMN as_ip;

then create the new ones:

  ALTER TABLE sessions
      ADD COLUMN as_wt varchar(255) COLLATE utf8mb4_bin
          AS (a_session->>'$._whatToTrace') VIRTUAL,
      ADD COLUMN as_sk varchar(32) COLLATE utf8mb4_bin
          AS (a_session->>'$._session_kind') VIRTUAL,
      ADD COLUMN as_ut bigint unsigned
          AS (cast(a_session->>'$._utime' as unsigned)) VIRTUAL,
      ADD COLUMN as_ls bigint unsigned
          AS (cast(a_session->>'$._lastSeen' as unsigned)) VIRTUAL,
      ADD COLUMN as_rt bigint unsigned
          AS (cast(a_session->>'$._oidcRtUpdate' as unsigned)) VIRTUAL,
      ADD COLUMN as_ip varchar(64) COLLATE utf8mb4_bin
          AS (a_session->>'$.ipAddr') VIRTUAL,
      ADD KEY as_wt (as_wt), ADD KEY as_sk (as_sk),
      ADD KEY as_ut (as_ut), ADD KEY as_ls (as_ls), ADD KEY as_rt (as_rt),
      ADD KEY as_ip (as_ip);

Use it with Perl:

  use Web::Session::MySQLJSON;

  my $args = {
       DataSource => 'dbi:mysql:sessions',
       UserName   => $db_user,
       Password   => $db_pass,
  };

Don't set C<Index>: any field can be searched from C<a_session> and the store
would try to write indexed fields into columns of the same name, which don't
exist in a JSON table. C<populate()> warns when C<Index> is set.

Field names and searched values are strings: a non flagged string containing
bytes C<0x80> or more is first tried as UTF-8 and read as Latin-1 if it is
not valid UTF-8, so both encodings find non-ASCII values.

Use it like the other backends of L<Web::Session>.
L<Web::Session::MySQL> is an alias of this module.

=head1 DESCRIPTION

Web::Session provides some class methods to manipulate all
sessions and add the capability to index some fields to make research faster.

Web::Session::MySQLJSON implements it for MySQL databases
using "json" type to be able to browse sessions.

=head2 searchLt() and searchGt()

  # Sessions whose _utime is lower than $time
  my $hash = Web::Session::MySQLJSON->searchLt( $args,
      '_utime', $time, 'uid' );

searchLt() and searchGt() take the same arguments and return the same data as
searchOn(): sessions whose field is lower (or greater) than the given value,
which is excluded. The value must be a number (C<12>, C<-12> or C<12.5>):
otherwise nothing is returned and an error is printed on STDERR. Spaces
around the value are ignored.

Fields are compared in SQL as deleteIfLowerThan() does
(C<cast(a_session-E<gt>E<gt>'$.field' as unsigned)>), so the index of a
generated column declared as C<as_ut> or C<as_rt> above is used. Values are
compared as unsigned integers: a non-numeric value is 0.

Sessions without the field are never returned. This differs from the Perl
fallback of Lemonldap::NG, where a missing field is compared as 0: searchLt()
would then return nearly all sessions. Lemonldap::NG doesn't need them: its
sessions purge ignores sessions without C<_oidcRtUpdate>.

Because of the unsigned cast, two cases differ from a numeric comparison: a
field stored as JSON C<null> is 0 (C<-E<gt>E<gt>> returns the string
C<null>), so searchLt() returns it, and a negative value becomes a huge
number (C<-5> is found by C<searchGt( $args, $field, 50 )>). Lemonldap::NG
timestamps are positive integers.

This module isn't usable with MariaDB: use
L<Web::Session::MariaDBJSON> instead.

=head2 Persistent connection

The database connection is kept open between sessions. Set
C<noreuse =E<gt> 1> to open and close one for each session, see
L<Web::Session/"PERSISTENT DATABASE CONNECTIONS">.

=head1 SEE ALSO

L<Apache::Session>, L<Web::Session::MySQL>,
L<Web::Session::MariaDBJSON>, L<http://lemonldap-ng.org>

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
