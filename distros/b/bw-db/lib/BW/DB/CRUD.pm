# CRUD.pm
# by Bill Weinman -- Database CRUD
#   Copyright (c) 1995-2008 The BearHeart Group, LLC
#
# based upon the old bwDB.pm
# Note bene: CRUD is Create, Retrieve, Update, and Delete
#
# See POD for History
#
package BW::DB::CRUD;
use strict;
use warnings;

use Digest::MD5;
use BW::Constants;
use base qw( BW::DB BW::Base );

our $VERSION = "0.10";

# _setter_getter entry points
sub id_type { BW::Base::_setter_getter(@_); }

### main crud methods

# sub getrec( table, id, options ... )
#
# caching getrec
#
# options:
#   refresh -- force refresh of cache from database
#
sub getrec
{
    my $sn   = 'getrec';
    my $self = shift or return undef;
    my $t    = shift or return $self->_error("$sn: no table name");
    my $id   = shift or return $self->_error("$sn: no id");
    my $opt  = shift || '';
    my $rc;

    my $cache = $self->{db_cache}{$t}{$id};
    if ( $cache and @$cache and $opt ne 'refresh' ) {
        return $cache;
    } else {
        $rc = $self->get( $t, "${t}_id", $id );
        return $self->{db_cache}{$t}{$id} = $rc if $rc and @$rc;
    }

    return VOID;
}

# sub putrec( table, id, rechash )
#
# caching update and insert
#
# old records will be updated based on id or rechash->{table_id}
# new records will be inserted with id or a new id
#
sub putrec
{
    my $sn       = 'putrec';
    my $self     = shift or return undef;
    my $t        = shift or return $self->_error("$sn: no table name");
    my $id       = shift || '';                                           # can be blank for new recs
    my $rechash  = shift or return $self->_error("$sn no rechash");
    my $table_id = $t . '_id';

    if ( $rechash->{$table_id} and !$id ) {
        $id = $rechash->{$table_id};
    }

    if ( $id and $self->getrec( $t, $id ) ) {
        $self->update( $t, $table_id, $id, $rechash ) or return FAILURE;
    } else {
        $id = $rechash->{$table_id} = $self->gen_id unless $id;
        $self->insert( $t, $rechash ) or return FAILURE;
    }

    return $self->{db_cache}{$t}{$id} = $rechash;
}

# sub delrec( table, id )
#
# caching delete
#
sub delrec
{
    my $sn   = 'delrec';
    my $self = shift or return undef;
    my $t    = shift or return $self->_error("$sn: no table name");
    my $id   = shift || '';                                           # can be blank for new recs

    # delete from cache
    delete $self->{db_cache}{$t}{$id} if $self->{db_cache}{$t}{$id};

    # delete from db
    return $self->delete( $t, $t . '_id', $id );
}

# delete ( table, key, value )
# returns TRUE or FALSE
sub delete
{
    my $self  = shift or return undef;
    my $table = shift or return undef;
    my $key   = shift or return undef;
    my $value = shift or return undef;

    $self->sql_connect                              unless $self->{dbh};
    return $self->_error("Database not connected.") unless $self->{dbh};

    my $query = "DELETE FROM $table WHERE $key = ?";
    return $self->sql_do( $query, $value );
}

# get ( table, key, value )
# returns hashref (from DBI) or FALSE
sub get
{
    my $sn = 'get';
    my ( $self, $table, $key, $value ) = @_;

    $self->sql_connect                              unless $self->{dbh};
    return $self->_error("Database not connected.") unless $self->{dbh};

    my $query = "SELECT * FROM $table WHERE $key = ?";
    return $self->sql_select( $query, $value );
}

# search
# alias for search_multi -- legacy support for a while
sub search { return search_multi(@_) }

# search_multi ( table, key, value )
# returns arrayref of hashes
# use for non-unique keys
sub search_multi
{
    my $self  = shift or return undef;
    my $table = shift or return undef;
    my $key   = shift or return undef;
    my $value = shift or return undef;

    $self->sql_connect                              unless $self->{dbh};
    return $self->_error("Database not connected.") unless $self->{dbh};

    my $query = "SELECT * FROM $table WHERE $key LIKE ? ORDER BY $key";
    return $self->sql_select( $query, $value );
}

# update ( table, key, value, { name => value, ... } )
sub update
{
    my $sn      = 'update';
    my $self    = shift or return undef;
    my $table   = shift or return undef;
    my $key     = shift or return undef;
    my $value   = shift or return undef;
    my $nvpairs = shift or return undef;
    my @cols;
    my @vals;

    $self->sql_connect                              unless $self->{dbh};
    return $self->_error("Database not connected.") unless $self->{dbh};

    foreach my $k ( keys %{$nvpairs} ) {
        push @cols, "$k = ?";
        push @vals, $nvpairs->{$k};
    }
    return undef unless ( @cols and @vals );

    my $query = "UPDATE $table SET " . join( ', ', @cols ) . " WHERE $key = ?";

    push @vals, $value;
    return $self->sql_do( $query, @vals );
}

### nv routines

# setnv ( object_type, object_id, name, value, attribute, flags, seq )
# requires a table named "nv"
sub setnv
{
    my $self = shift or return undef;
    my $sn = 'setnv';
    my ( $t, $id, $n, $v, $a, $f, $s ) = @_;
    return $self->_error("$sn: missing object type") unless $t;
    return $self->_error("$sn: missing object id")   unless $id;
    return $self->_error("$sn: missing name")        unless $n;
    return $self->_error("$sn: missing value")       unless $v;

    my $rec = {
        object_type => $t,
        object_id   => $id,
        name        => $n,
        value       => $v
    };

    $rec->{attribute} = $a if $a;
    $rec->{flags}     = $f if $f;
    $rec->{seq}       = $s if $s;

    my $rc = $self->putrec( 'nv', undef, $rec );
    if ( $rc->{nv_id} ) {
        return $rc->{nv_id};
    } else {
        return $self->{FALSE};
    }
}

# getnv ( t, id, n )
# returns hash of first rec found
# if no n, error
sub getnv
{
    my $self = shift or return undef;
    my $sn = 'getnv';
    my ( $t, $id, $n ) = @_;
    return $self->_error("$sn: missing object type") unless $t;
    return $self->_error("$sn: missing object id")   unless $id;
    return $self->_error("$sn: missing object name") unless $n;

    return $self->sql_select(
        qq{
      SELECT * FROM nv WHERE object_type = ? AND object_id = ? AND name = ?
    }, $t, $id, $n
    );
}

# searchnv ( t, id, name, value, attribute )
# returns arrayref of hashes { keys: nv_id, object_type, object_id, name, value }
# if no n, returns all nvs for t, id
sub searchnv
{
    my $self = shift or return undef;
    my $sn = 'searchnv';
    my ( $t, $id, $n, $v, $a ) = @_;
    return $self->_error("$sn: missing object type") unless $t;
    return $self->_error("$sn: missing object id")   unless $id;
    return $self->_error("$sn: missing nv name")     unless $n;

    my $sql = qq{ SELECT * FROM nv WHERE object_type = ? AND object_id = ? AND name = ? };

    my @nvp = ( $t, $id, $n );

    if ($v) {
        $sql .= qq{ AND value = ? };
        push( @nvp, $v );
    }

    if ($a) {
        $sql .= qq{ AND attribute = ? };
        push( @nvp, $a );
    }

    $sql .= qq{ ORDER BY seq };

    return $self->sql_select( $sql, @nvp );
}

# updnv ( nv_id, value, attribute )
# updates rec with new v
# returns TRUE (success) or FALSE (failure)
sub updnv
{
    my $self = shift or return undef;
    my $sn = 'updnv';
    my ( $nv_id, $v, $a ) = @_;
    my $rec;
    return $self->_error("$sn: missing nv_id") unless $nv_id;
    return $self->_error("$sn: missing value") unless $v;

    return $self->_error("$sn: nv $nv_id not found") unless $rec = $self->getrec( 'nv', $nv_id );

    $rec->{value}     = $v if $v;
    $rec->{attribute} = $a if $a;

    return $self->putrec( 'nv', $nv_id, $rec );
}

# delnv ( nv_id )
# deletes nv rec
sub delnv
{
    my $self  = shift or return undef;
    my $sn    = 'delnv';
    my $nv_id = shift or return $self->_error("$sn: no nv_id");

    return $self->delrec( 'nv', $nv_id );
}

### utilty routines

# return a list of fields for a given table
sub fields_list
{
    my $self       = shift or return undef;
    my $table_name = shift or return undef;
    my $fields_list;

    return $fields_list if ( $fields_list = $self->{fields_cache}{$table_name} );

    my $query = " SHOW COLUMNS from $table_name ";    # this is likely mysql-specific
    $fields_list = $self->{dbh}->selectcol_arrayref( $query, { Columns => [1] } );
    $self->{fields_cache}{$table_name} = $fields_list;
    return $fields_list || undef;
}

sub gen_id
{
    my $self = shift or return undef;
    my $id_type = $self->id_type || '';
    if ( $id_type eq 'base64' ) {
        return $self->gen_id_base64;
    } else {
        return $self->gen_id_md5hash;
    }
}

sub gen_id_md5hash
{
    my $self = shift or return undef;
    return $self->md5hash();
}

sub gen_id_base64
{
    my $self = shift or return undef;
    return $self->md5base64();
}

sub md5base64    # returns a url-safe base-64 MD5 hash for use as an ID field
{
    my ( $self, $parm ) = @_;
    $parm = 'unk' unless $parm;
    my $r = Digest::MD5::md5_base64( $$, time, rand, $parm );
    $r =~ tr|+/|!-|;    # '+' and '/' chars are nasty for URLs
    return $r;
}

sub md5hash
{
    return Digest::MD5::md5_hex( $$, time, rand );
}

1;

=head1 NAME

BW::DB::CRUD - Database CRUD

=head1 SYNOPSIS

  Database CRUD: (C)reate, (R)etrieve, (U)pdate, (D)elete

  use BW::DB::CRUD;
  my $o = BW::DB::CRUD->new;

=head1 METHODS

=over 4

=item B<new>( )

Constructs a new BW::DB::CRUD object. 

Returns a blessed BW::DB::CRUD object reference.
Returns undef (VOID) if the object cannot be created. 

=item B<error>

Returns and clears the object error message.

=back

=head1 WARNING

This module is currently in an unfinished state. Do not use this
for new projects. The interface WILL change. 

=head1 AUTHOR

Written by Bill Weinman E<lt>http://bw.org/E<gt>.

=head1 COPYRIGHT

Copyright (c) 1995-2010 The BearHeart Group, LLC

=head1 HISTORY

  2010-02-17 bw     -- first CPAN version - not ready for prime time!
  2008-03-27 bw     -- cleanup for publishing
  2007-10-21 bw     -- fixed a caching bug in getrec
  2007-10-19 bw     -- initial version.

=cut

