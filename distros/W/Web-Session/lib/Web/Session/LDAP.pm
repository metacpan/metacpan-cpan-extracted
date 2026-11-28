package Web::Session::LDAP;

use strict;

use Apache::Session;
use Apache::Session::Lock::Null;
use Web::Session::Store::LDAP;
use Web::Session::Generate::SHA256;
use Web::Session::Serialize::JSON;
use Web::Session::_common;
use Net::LDAP::Constant
  qw(LDAP_CONTROL_PAGED LDAP_NO_SUCH_OBJECT LDAP_ASSERTION_FAILED
  LDAP_UNAVAILABLE_CRITICAL_EXT);
use Net::LDAP::Control::Assertion;
use Net::LDAP::Control::Paged;
use Net::LDAP::Util qw(escape_filter_value);

our $VERSION = '1.0.0';
our @ISA     = qw(Apache::Session Web::Session::_common);

# Page size of searches that may return many entries
our $PageSize = 500;

my $numRe = qr/^(-?)([0-9]+)(?:\.([0-9]+))?\z/;

sub populate {
    my $self = shift;

    $self->{object_store} = new Web::Session::Store::LDAP $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Web::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Web::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Web::Session::Serialize::JSON::serialize;
    $self->{unserialize}  = \&Web::Session::Serialize::JSON::unserialize;

    return $self;
}

sub unserialize {
    my $session = shift;
    my $tmp     = { serialized => $session };
    Web::Session::Serialize::JSON::unserialize($tmp);
    return $tmp->{data};
}

sub searchOn {
    my ( $class, $args, $selectField, $value, @fields ) = @_;

    my $index =
      ref( $args->{Index} ) ? $args->{Index} : [ split /\s+/, $args->{Index} ];
    if ( grep { $_ eq $selectField } @$index ) {
        ( $selectField, $value ) = escape_filter_value( $selectField, $value );
        return $class->_query( $args, $selectField, $value, @fields );
    }
    else {
        return $class->SUPER::searchOn( $args, $selectField, $value, @fields );
    }
}

sub searchOnExpr {
    my ( $class, $args, $selectField, $value, @fields ) = @_;

    my $index =
      ref( $args->{Index} ) ? $args->{Index} : [ split /\s+/, $args->{Index} ];
    if ( grep { $_ eq $selectField } @$index ) {
        ( $selectField, $value ) = escape_filter_value( $selectField, $value );
        $value =~ s/\\2a/\*/gi;
        return $class->_query( $args, $selectField, $value, @fields );
    }
    else {
        return $class->SUPER::searchOn( $args, $selectField, $value, @fields );
    }
}

sub searchLt {
    my $class = shift;
    return $class->_searchCmp( -1, @_ );
}

sub searchGt {
    my $class = shift;
    return $class->_searchCmp( 1, @_ );
}

# The index attribute has no ordering rule and a substring filter can't bound
# the length of a number, so the index only restricts the search to sessions
# having the field. Values are compared in Perl; sessions without the field or
# where it isn't a number are skipped. LDAP errors return an empty result:
# Lemonldap::NG purge doesn't catch them.
sub _searchCmp {
    my ( $class, $sign, $args, $selectField, $value, @fields ) = @_;
    my $name = 'search' . ( $sign < 0 ? 'Lt' : 'Gt' );
    $value =~ s/^\s+|\s+$//g if ( defined $value );
    unless ( defined $value and $value =~ $numRe ) {
        print STDERR "$name: value must be a number\n";
        return {};
    }
    $class->_defaults($args);

    my $filter =
        $class->_fieldIsIndexed( $args, $selectField )
      ? $class->_presenceFilter( $args, $selectField )
      : "($args->{ldapAttributeId}=*)";
    my %res = ();
    my $ldap =
      eval { Web::Session::Store::LDAP->new($args)->ldap };
    unless ($ldap) {
        print STDERR "$name: unable to connect: $@\n";
        return {};
    }
    my $msg = $class->_pagedSearch(
        $ldap,
        sub {
            my $entry = shift;
            my $id    = $entry->get_value( $args->{ldapAttributeId} ) or return;
            my $tmp   = $entry->get_value( $args->{ldapAttributeContent} );
            return unless $tmp;
            eval { $tmp = unserialize($tmp); };
            return if $@;
            my $cmp = $class->_cmpNum( $tmp->{$selectField}, $value );
            return unless ( defined $cmp and $cmp == $sign );

            if (@fields) {
                $res{$id}->{$_} = $tmp->{$_} foreach (@fields);
            }
            else {
                $res{$id} = $tmp;
            }
        },
        base   => $args->{ldapConfBase},
        scope  => 'one',
        filter => "(&(objectClass=$args->{ldapObjectClass})$filter)",
        attrs  => [ $args->{ldapAttributeId}, $args->{ldapAttributeContent} ],
    );
    $ldap->unbind();
    $ldap->disconnect();
    if ($msg) {
        print STDERR "$name: LDAP error "
          . $msg->code . ': '
          . $msg->error . "\n";
        return {};
    }

    return \%res;
}

sub _query {
    my ( $class, $args, $selectField, $value, @fields ) = @_;
    my %res = ();
    $args->{ldapObjectClass}      ||= 'applicationProcess';
    $args->{ldapAttributeId}      ||= 'cn';
    $args->{ldapAttributeContent} ||= 'description';
    $args->{ldapAttributeIndex}   ||= 'ou';

    my $obj  = Web::Session::Store::LDAP->new($args);
    my $ldap = $obj->ldap();
    my $msg  = $class->_pagedSearch(
        $ldap,
        sub {
            my $entry = shift;
            my $id    = $entry->get_value( $args->{ldapAttributeId} ) or die;
            my $tmp   = $entry->get_value( $args->{ldapAttributeContent} );
            return unless $tmp;
            eval { $tmp = unserialize($tmp); };
            return if ($@);
            if (@fields) {
                $res{$id}->{$_} = $tmp->{$_} foreach (@fields);
            }
            else {
                $res{$id} = $tmp;
            }
        },
        base   => $args->{ldapConfBase},
        scope  => 'one',
        filter => "(&(objectClass="
          . $args->{ldapObjectClass} . ")("
          . $args->{ldapAttributeIndex}
          . "=${selectField}_$value))",
        attrs => [ $args->{ldapAttributeContent}, $args->{ldapAttributeId} ],
    );
    $ldap->unbind();
    $ldap->disconnect();
    $obj->logError($msg) if $msg;

    return \%res;
}

sub get_key_from_all_sessions {
    my $class = shift;
    my $args  = shift;
    my $data  = shift;
    $args->{ldapObjectClass}      ||= 'applicationProcess';
    $args->{ldapAttributeId}      ||= 'cn';
    $args->{ldapAttributeContent} ||= 'description';
    $args->{ldapAttributeIndex}   ||= 'ou';

    my %res  = ();
    my $obj  = Web::Session::Store::LDAP->new($args);
    my $ldap = $obj->ldap();
    my $msg  = $class->_pagedSearch(
        $ldap,
        sub {
            my $entry = shift;
            my $id    = $entry->get_value( $args->{ldapAttributeId} ) or die;
            my $tmp   = $entry->get_value( $args->{ldapAttributeContent} );
            return unless ($tmp);
            eval { $tmp = unserialize($tmp); };
            return if $@;
            if ( ref($data) eq 'CODE' ) {
                $res{$id} = &$data( $tmp, $id );
            }
            elsif ($data) {
                $data = [$data] unless ( ref($data) );
                $res{$id}->{$_} = $tmp->{$_} foreach (@$data);
            }
            else {
                $res{$id} = $tmp;
            }
        },
        base  => $args->{ldapConfBase},
        scope => 'one',

     # VERY STRANGE BUG ! With this filter, description isn't base64 encoded !!!
     #filter => '(objectClass=applicationProcess)',

        # Sessions without any indexed value have no index attribute
        filter => '(&(objectClass='
          . $args->{ldapObjectClass} . ')('
          . $args->{ldapAttributeId} . '=*))',
        attrs => [ $args->{ldapAttributeId}, $args->{ldapAttributeContent} ],
    );

    $ldap->unbind();
    $ldap->disconnect();
    $obj->logError($msg) if $msg;

    return \%res;
}

# Only index values are read: candidates are selected by the directory, then
# checked in Perl. Returns false if the rule can't be evaluated this way (the
# caller then falls back to a full scan), true on success; in list context,
# also the number of deleted sessions: 0 when it returns false, otherwise the
# number deleted, or already deleted if an error stops the deletions.
sub deleteIfLowerThan {
    my ( $class, $args, $rule ) = @_;
    my $filter = $class->_lowerThanFilter( $args, $rule )
      or return wantarray ? ( 0, 0 ) : 0;

    my $ldap =
      eval { Web::Session::Store::LDAP->new($args)->ldap };
    unless ($ldap) {
        print STDERR "deleteIfLowerThan: unable to connect: $@\n";
        return wantarray ? ( 0, 0 ) : 0;
    }

    # Collect first: nothing is deleted if the search fails
    my @found;
    my $msg = $class->_pagedSearch(
        $ldap,
        sub {
            my $entry  = shift;
            my @values = $entry->get_value( $args->{ldapAttributeIndex} );
            push @found, [ $entry->dn, @values ]
              if $class->_matchLowerThan( $rule, @values );
        },
        base   => $args->{ldapConfBase},
        scope  => 'one',
        filter => $filter,
        attrs  => [ $args->{ldapAttributeIndex} ],
    );
    my ( $ok, $deleted ) = ( 1, 0 );
    foreach ( $msg ? () : @found ) {
        my ( $dn, @values ) = @$_;
        my $keep;
        ( $keep, $msg ) =
          $class->_notInContent( $ldap, $args, $rule, $dn, @values );
        last if $msg;
        next if $keep;

        # Don't delete sessions updated since the search. The control is
        # critical: a server ignoring it would delete refreshed sessions
        my $res = $ldap->delete(
            $dn,
            control => [
                Net::LDAP::Control::Assertion->new(
                    critical  => 1,
                    assertion =>
                      $class->_lowerThanAssertion( $args, $rule, @values )
                )
            ]
        );
        if ( !$res->code ) {
            $deleted++;
        }

        # Already removed (by a logout for example) or updated
        elsif ( $res->code != LDAP_NO_SUCH_OBJECT
            and $res->code != LDAP_ASSERTION_FAILED )
        {
            $msg = $res;
            last;
        }
    }
    if ($msg) {
        print STDERR 'deleteIfLowerThan: LDAP error '
          . $msg->code . ': '
          . $msg->error . "\n";
        print STDERR "deleteIfLowerThan: the server doesn't support the "
          . "assertion control (RFC 4528), giving up\n"
          if ( $msg->code == LDAP_UNAVAILABLE_CRITICAL_EXT );
        $ok = 0;
    }
    $ldap->unbind();
    $ldap->disconnect();

    return wantarray ? ( $ok, $deleted ) : $ok;
}

# A session written before a "not" field was added to Index has no index
# value for it: read its content. Returns true if the session must be kept,
# and the failed LDAP message if any
sub _notInContent {
    my ( $class, $ldap, $args, $rule, $dn, @values ) = @_;
    my $not   = $rule->{not} || {};
    my @stale = grep {
        my $prefix = "${_}_";
        !grep { index( $_, $prefix ) == 0 } @values
    } sort keys %$not;
    return 0 unless @stale;

    my $msg = $ldap->search(
        base   => $dn,
        scope  => 'base',
        filter => '(objectClass=*)',
        attrs  => [ $args->{ldapAttributeContent} ],
    );
    return ( 1, $msg ) if ( $msg->code and $msg->code != LDAP_NO_SUCH_OBJECT );
    my $data = eval {
        unserialize(
            $msg->shift_entry->get_value( $args->{ldapAttributeContent} ) );
    };

    # Removed meanwhile or unreadable: keep it
    return 1 unless ( ref $data eq 'HASH' );
    foreach (@stale) {
        return 1
          if ( defined $data->{$_} and lc( $data->{$_} ) eq lc( $not->{$_} ) );
    }
    return 0;
}

# Assertion checking that the index values used to select a session are
# unchanged: the observed rule values are still there, "not" values still
# missing
sub _lowerThanAssertion {
    my ( $class, $args, $rule, @values ) = @_;
    my $ou  = $args->{ldapAttributeIndex};
    my $lt  = $rule->{ exists $rule->{or} ? 'or' : 'and' };
    my $not = $rule->{not} || {};
    my $res = '';
    foreach my $f ( sort keys %$lt ) {
        $res .= "($ou=" . escape_filter_value($_) . ')'
          foreach ( grep { index( $_, "${f}_" ) == 0 } @values );
    }
    $res .= "(!($ou=" . escape_filter_value("${_}_$not->{$_}") . '))'
      foreach ( sort keys %$not );
    return "(&$res)";
}

# $rule: { or|and => { field => number, ... }, not => { field => value, ... } }
# Returns the filter selecting candidate entries: those having the "or"/"and"
# fields and none of the "not" values. Every field must be indexed.
sub _lowerThanFilter {
    my ( $class, $args, $rule ) = @_;
    return unless ( ref $rule eq 'HASH' );
    my @op = grep { exists $rule->{$_} } qw(or and);
    return unless ( @op == 1 );
    my $lt  = $rule->{ $op[0] };
    my $not = $rule->{not} || {};
    return unless ( ref $lt eq 'HASH' and %$lt and ref $not eq 'HASH' );
    foreach my $v ( values %$lt ) {
        my $t = ( defined $v and !ref $v ) ? $v : '';
        $t =~ s/^\s+|\s+$//g;
        unless ( $t =~ $numRe ) {
            print STDERR "deleteIfLowerThan: threshold must be a number\n";
            return;
        }
    }

    # Empty and "0" values aren't indexed, so "not" can't exclude them
    foreach ( values %$not ) {
        return unless ( defined $_ and !ref $_ and $_ );
    }
    foreach ( keys %$lt, keys %$not ) {
        return unless $class->_fieldIsIndexed( $args, $_ );
    }
    $class->_defaults($args);

    my @terms  = map { $class->_presenceFilter( $args, $_ ) } sort keys %$lt;
    my $filter = join '', @terms;
    $filter = ( $op[0] eq 'or' ? '(|' : '(&' ) . "$filter)" if ( @terms > 1 );
    foreach ( sort keys %$not ) {
        $filter .= "(!($args->{ldapAttributeIndex}="
          . escape_filter_value("${_}_$not->{$_}") . '))';
    }
    return "(&(objectClass=$args->{ldapObjectClass})$filter)";
}

# Checks a rule accepted by _lowerThanFilter() against the index values of an
# entry. A field is lower only if it has numeric values, all lower.
sub _matchLowerThan {
    my ( $class, $rule, @values ) = @_;
    my $not = $rule->{not} || {};
    foreach my $f ( keys %$not ) {
        return 0 if grep { $_ eq "${f}_$not->{$f}" } @values;
    }
    my $or = exists $rule->{or};
    my $lt = $rule->{ $or ? 'or' : 'and' };
    foreach my $f ( keys %$lt ) {

        # Same parsing as searchLt(): surrounding spaces are ignored
        my @nums =
          grep { defined $class->_cmpNum( $_, $lt->{$f} ) }
          map  { /^\Q$f\E_(.*)\z/s ? $1 : () } @values;
        my $low = @nums ? 1 : 0;
        foreach (@nums) {
            $low = 0 unless ( $class->_cmpNum( $_, $lt->{$f} ) < 0 );
        }
        return 1 if ( $low  and $or );
        return 0 if ( !$low and !$or );
    }
    return $or ? 0 : 1;
}

sub _defaults {
    my ( $class, $args ) = @_;
    $args->{ldapObjectClass}      ||= 'applicationProcess';
    $args->{ldapAttributeId}      ||= 'cn';
    $args->{ldapAttributeContent} ||= 'description';
    $args->{ldapAttributeIndex}   ||= 'ou';
}

# Matches entries having an index value for $field. It may also match other
# fields whose name starts with "${field}_": callers check values in Perl
sub _presenceFilter {
    my ( $class, $args, $field ) = @_;
    return
      "($args->{ldapAttributeIndex}=" . escape_filter_value("${field}_") . '*)';
}

# Calls $cb on each entry, page by page to avoid server size limits. Returns
# the failed LDAP message, or nothing on success
sub _pagedSearch {
    my ( $class, $ldap, $cb, %search ) = @_;
    my $page = Net::LDAP::Control::Paged->new( size => $PageSize );
    my $cookie;
    while (1) {
        my $msg = $ldap->search( %search, control => [$page] );
        return $msg if $msg->code;
        $cb->($_) foreach ( $msg->entries );

        my ($resp) = $msg->control(LDAP_CONTROL_PAGED);

        # Servers without paged results support return everything at once, but
        # a full page may hide a truncated result
        unless ($resp) {
            print STDERR
              "paged search: no paged results control in the response, "
              . "results may be truncated\n"
              if ( defined $cookie or $msg->count >= $PageSize );
            return;
        }
        return unless ( $resp->cookie );

        # A server or proxy returning a constant cookie would loop forever
        if ( defined $cookie and $resp->cookie eq $cookie ) {
            print STDERR "paged search: cookie didn't change, stopping\n";
            return;
        }
        $page->cookie( $cookie = $resp->cookie );
    }
}

# Exact comparison of two decimal numbers given as strings (no float
# rounding), surrounding spaces ignored: returns -1, 0 or 1, undef if one of
# them isn't a number
sub _cmpNum {
    my ( $class, @v ) = @_;
    foreach (@v) {
        return undef unless ( defined $_ and !ref $_ );
        s/^\s+|\s+$//g;
        return undef unless ( $_ =~ $numRe );
        my ( $sign, $int, $frac ) = ( $1 ? -1 : 1, $2, defined $3 ? $3 : '' );
        $int  =~ s/^0+//;
        $frac =~ s/0+\z//;
        $sign = 1 unless ( length $int or length $frac );
        $_    = [ $sign, $int, $frac ];
    }
    my ( $x, $y ) = @v;
    return $x->[0] <=> $y->[0] if ( $x->[0] != $y->[0] );
    my $cmp =
         length( $x->[1] ) <=> length( $y->[1] )
      || $x->[1] cmp $y->[1]
      || $x->[2] cmp $y->[2];
    return $x->[0] * $cmp;
}

1;

=pod

=head1 NAME

Web::Session::LDAP - An implementation of Apache::Session::LDAP

=head1 SYNOPSIS

  use Web::Session::LDAP;
  tie %hash, 'Web::Session::LDAP', $id, {
    ldapServer           => 'ldap://localhost:389',
    ldapConfBase         => 'dmdName=applications,dc=example,dc=com',
    ldapBindDN           => 'cn=admin,dc=example,dc=com',
    ldapBindPassword     => 'pass',
    Index                => 'uid ipAddr',
    ldapObjectClass      => 'applicationProcess',
    ldapAttributeId      => 'cn',
    ldapAttributeContent => 'description',
    ldapAttributeIndex   => 'ou',
    ldapVerify           => 'require',
    ldapCAFile           => '/etc/ssl/certs/ca-certificates.crt',
    ldapTimeout          => 10,
  };

=head1 DESCRIPTION

This module is an implementation of Apache::Session. It uses an LDAP directory
to store datas.

See L<Web::Session::Store::LDAP> for the available options.

Each session is an entry named C<ldapAttributeId=id,ldapConfBase> (default
objectClass C<applicationProcess>, available in the core schema). The session
is serialized in JSON into C<ldapAttributeContent>, and each field listed in
C<Index> and set in the session is stored as a C<field_value> value of
C<ldapAttributeIndex>. Fields whose value is empty or C<0> are not indexed.

The directory should index C<ldapAttributeIndex> for equality and substring
searches (OpenLDAP: C<index ou eq,sub>).

=head2 searchLt() and searchGt()

  # Refresh tokens not updated since 1 hour
  my $hash = Web::Session::LDAP->searchLt( $args,
      '_oidcRtUpdate', time - 3600 );
  my $hash = Web::Session::LDAP->searchGt( $args,
      '_utime', time - 3600, 'uid', 'ipAddr' );

Return sessions whose field is strictly lower (or greater) than the given
number, like searchOn(). Sessions without the field, or where it isn't a
number, are skipped. The value must be a decimal number
(C</^-?[0-9]+(?:\.[0-9]+)?$/>), otherwise an empty result is returned with a
warning. LDAP errors also return an empty result with a warning.

The index attribute has no ordering matching rule, and substring filters
can't bound the length of a number, so the directory can't select the lower
values. When the field is indexed, only sessions having it are read; otherwise
all sessions are read. Numbers are then compared in Perl. Lemonldap::NG purge
calls searchLt() on C<_oidcRtUpdate> when a refresh token activity timeout is
set: add it to C<Index>.

When the field is indexed, sessions are found through their index values:
sessions whose value is C<0> or empty, or written before the field was added
to C<Index>, are missed until they are rewritten.

Differences with the SQL backends (searchLt(), searchGt() and
deleteIfLowerThan()):

=over

=item * Values which aren't numbers are ignored here, whereas SQL backends
compare them as C<0> or by their numeric prefix (C<12abc> is C<12>).

=item * Fields whose value is C<0> or empty are not indexed, so they are
missed when the field is indexed, whereas SQL backends find them.

=back

=head2 deleteIfLowerThan()

  my ( $ok, $count ) = Web::Session::LDAP->deleteIfLowerThan(
      $args,
      {
          not => { _session_kind => 'Persistent' },
          or  => { _utime => time - 7200, _lastSeen => time - 3600 },
      }
  );

Deletes sessions where one (C<or>) or all (C<and>) of the given fields are
strictly lower than their threshold, and where each C<not> field is missing
or has another value. Exactly one of C<or> and C<and> must be given, and
thresholds must be decimal numbers (surrounding spaces are ignored). A missing
field, or one which isn't a number, is never lower.

Only the index is used: every field of the rule must be listed in C<Index>.
For Lemonldap::NG sessions purge, index C<_session_kind> and C<_utime>, plus
C<_lastSeen> when "timeoutActivity" is set and C<_oidcRtUpdate> for
searchLt() (see above), for example:

  Index => '_whatToTrace _session_kind _utime _lastSeen _oidcRtUpdate ipAddr'

The directory selects the sessions having the C<or>/C<and> fields and none of
the C<not> values, for example:

  (&(objectClass=applicationProcess)(|(ou=_lastSeen_*)(ou=_utime_*))
    (!(ou=_session_kind_Persistent)))

Only their DN and index values are read; numbers are compared in Perl, then
the matching entries are deleted. As with searchLt(), no filter can select
lower numbers: C<ou> has no ordering rule, and a substring filter can't tell
C<99> from C<9900000000>. So the index values of all the candidate sessions
are read, but much less data than the full scan used otherwise.

The serialized session is only read when a matching session has no index
value for a C<not> field (written before this field was added to C<Index>):
it is kept if its content has the C<not> value.

Each deletion carries an assertion control (RFC 4528) checking that the index
values seen by the search haven't changed: a session updated in the meantime
is not deleted. The control is critical: if the server (or a proxy) doesn't
support it, the deletion fails with LDAP error 12, and deleteIfLowerThan()
stops and returns false (see below) so that no refreshed session is deleted.

Limits:

=over

=item * The rule fields are read from the index: after adding a field to
C<Index>, sessions written before are ignored until they are rewritten.

=item * C<not> values are compared with the equality rule of the index
attribute: case-insensitive for C<ou>, so C<persistent> is also kept.

=item * Fields whose value is empty or C<0> aren't indexed: they are
considered missing, and a C<not> value empty or C<0> is refused.

=back

Returns false, deleting nothing (0 in list context), if the rule can't be
handled this way (non indexed field, invalid threshold...) or if the
connection or the search fails: Lemonldap::NG then falls back to reading all
sessions. Otherwise returns true and, in list context, the number of deleted
sessions (sessions removed or updated meanwhile aren't counted). If a deletion
fails, stops and returns false, and in list context the number of sessions
already deleted.

=head2 Size limits

Searches returning many sessions (get_key_from_all_sessions(), searchOn(),
searchOnExpr(), searchLt(), searchGt(), deleteIfLowerThan()) use the paged
results control. With OpenLDAP, if the bind DN isn't the rootdn, allow it to
read all sessions, for example with
C<limits dn.exact="E<lt>bind DNE<gt>" size=unlimited> (this covers paged and
unpaged searches).

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
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Apache::Session>

=cut
