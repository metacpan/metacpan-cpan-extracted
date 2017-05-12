##
#
#    Copyright 2004-2005, AllAfrica Global Media
#
#    This file is part of XML::Comma
#
#    XML::Comma is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about XML::Comma, point a web browser at
#    http://xml-comma.org, or read the tutorial included
#    with the XML::Comma distribution at docs/guide.html
#
##

# A work in progress -- not yet close to functional. There are lots of
# issues with our assumptions about how to handle errors versus who
# sqlite throws them, with autocommit stuff, with the "schema has
# changed" error the sqlite throws, and with frequent mid-script
# losses of connection to the db.

#   here's a block for the Configuration file
#

# sqlite => {
#              sql_syntax  =>  'SQLite',
#              dbi_connect_info => [
#                                   'DBI:SQLite:test.db', '', '',
#                                   { RaiseError => 1,
#                                     PrintError => 1,
#                                     ShowErrorStatement => 1,
#                                     AutoCommit => 1,
#   HandleError => sub {
#     my ( $string, $handle ) = @_;
#     # print "handling error ($handle)\n";
#     if ( $string =~ m|schema has changed| ) {
#       $handle->execute();
#       return 1;
#     }
#     return;
#   }
#                                   } ],
#             },

package XML::Comma::SQL::SQLite;

use XML::Comma::Util qw( dbg );
use MIME::Base64;

use base qw( XML::Comma::SQL::Base );

use strict;

# due to some SQLite futziness, we need to implement our own ping
# and call it before every prepare in order to ensure that we have
# a viable database handle.  By "implement our own ping", I mean
# we stuff one in DBH_User from over here.

# we have to wait until this package is completely parsed before
# we can force-feed DBH_User our ping else we get in a BEGIN
# block race, hence the INIT.
INIT {

  *XML::Comma::SQL::DBH_User::ping = \&ping;

}

sub sql_create_lock_table {
  my $lock = shift;
  $lock->ping();
  my $dbh  = $lock->get_dbh_writer();
  my $sth = $dbh->prepare_cached (
    qq[
        CREATE TABLE comma_lock
            ( doc_key         VARCHAR(255) UNIQUE,
              pid             INT,
              info            VARCHAR(255),
              time            INT )
    ]);
  $sth->execute();
  $sth->finish();
}

sub sql_create_hold_table {
  my $lock = shift;
  $lock->ping();
  my $dbh  = $lock->get_dbh_writer();
  my $sth = $dbh->prepare_cached(
    qq[
        CREATE TABLE comma_hold ( key VARCHAR(255) UNIQUE )
    ]);
  $sth->execute();
  $sth->finish();
}

# $lock, $key
sub sql_get_lock_record {
  my ($lock, $key) = @_;
  $lock->ping();
  my $dbh  = $lock->get_dbh_reader();
  my $sth = $dbh->prepare_cached (
    qq[
        SELECT doc_key, pid, info, time
            FROM comma_lock
            WHERE doc_key = ?
    ]);
  $sth->execute( $key );
  my $result = $sth->fetchrow_arrayref();
  $sth->finish();
  return $result ? { doc_key => $result->[0],
                     pid     => $result->[1],
                     info    => $result->[2],
                     time    => $result->[3] } : '';
}

# $lock
sub sql_delete_locks_held_by_this_pid {
  my $lock = shift;
  $lock->ping();
  my $dbh  = $lock->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ DELETE from comma_lock 
            WHERE pid = ? ]
  );
  $sth->execute( $$ );
  $sth->finish();
}

# $lock, $key - returns 1 if row-insert succeeds, 0 on duplicate
# key. throws error for any error other than duplicate key.
sub sql_doc_lock {
  my ($lock, $key) = @_;
  $lock->ping();
  my $dbh = $lock->get_dbh_writer();
  eval { 
    my $sth = $dbh->prepare_cached (
      qq[ 
          INSERT INTO comma_lock ( doc_key, pid, time, info )
              VALUES ( ?, ?, ?, ? ) 
      ]);
    $sth->execute( $key, $$, time(), Sys::Hostname::hostname() );
    $sth->finish();
  }; if ( $@ ) {
    # dbg 'sql lock insert error', $@; we actually want to get an
    # error on a failed lock. we catch the error and check whether it
    # signals an attempt to insert a "duplicate" key. If so, the lock
    # attempt failed, so we return 0.
    if ( $@ =~ /duplicate/i ) {
      # print "lock on $_[1] failed\n";
      return 0;
    }
    die "Err, $@\n";
  }
  return 1;
}

# $lock, $key
sub sql_doc_unlock {
  my ($lock, $key) = @_;
  my $dbh  = $lock->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ 
        DELETE FROM comma_lock 
            WHERE doc_key = ? 
    ]);
  $sth->execute( $key );
  $sth->finish();
}

sub sql_get_hold {
  my ( $lock, $key ) = @_;
  $lock->ping();
  my $dbh = $lock->get_dbh_writer();
  dbg 'getting hold', $key;
  my $sth = $dbh->prepare_cached ( 
    qq[
        INSERT INTO comma_hold (key) VALUES (?)
    ]);
  eval {
    $sth->execute( $key );
  };  
  XML::Comma::Log->err( $@ ) if $@;
  $sth->finish();
}

sub sql_release_hold {
  my ( $lock, $key ) = @_;
  $lock->ping();
  # $lock->reconnect();
  my $dbh = $lock->get_dbh_writer();
  dbg 'releasing hold', $key;
  my $sth = $dbh->prepare_cached ( 
    qq[
        DELETE FROM comma_hold WHERE key = ?
    ]);
  eval {
    $sth->execute( $key );
  };
  XML::Comma::Log->err( $@ ) if $@;
  $sth->finish();
}

sub sql_create_index_tables_table {
  my $index = shift();
  $index->ping();
  my $dbh   = $index->get_dbh_writer();
  my $sth   = $dbh->prepare_cached (
    qq[
        CREATE TABLE index_tables
          ( _comma_flag    INTEGER,
            _sq            INTEGER PRIMARY KEY UNIQUE,
            doctype        VARYING CHARACTER(255),
            index_name     VARYING CHARACTER(255),
            table_name     VARYING CHARACTER(255),
            table_type     INTEGER,
            last_modified  INTEGER,
            sort_spec      VARYING CHARACTER(255),
            textsearch     VARYING CHARACTER(255),
            collection     VARYING CHARACTER(255),
            index_def      CLOB )
    ]);
  $sth->execute();
  $sth->finish();
}


sub sql_sort_table_definition {
  my $doc_id = $_[0]->element('doc_id_sql_type')->get();
  return qq[ 
    CREATE TABLE $_[1] (
       _comma_flag  INT2,
       doc_id $doc_id PRIMARY KEY
    )
  ];
}


sub sql_bcollection_table_definition {
  my ( $index, $name, %arg ) = @_;
  my $extra_column = '';
  if ( @{$arg{bcoll_el}->elements('field')} ) {
    $extra_column = ", extra " .
      $arg{bcoll_el}->element('field')->element('sql_type')->get();
  }

  return
"CREATE TABLE $name (
  _comma_flag  INT2,
  doc_id ${ \( $index->element('doc_id_sql_type')->get() ) },
  value   ${ \( $arg{bcoll_el}->element('sql_type')->get() ) }
  $extra_column
 );
 CREATE INDEX bci_$name ON $name (value)";
}


sub sql_textsearch_index_table_definition {
  my $max_length = $XML::Comma::Pkg::Textsearch::Preprocessor::max_word_length;
  return
"CREATE TABLE $_[1] (
  word  CHAR($max_length)  PRIMARY KEY,
  seqs  TEXT )";
}

sub sql_textsearch_defers_table_definition {
  return
"CREATE TABLE $_[1] (
  doc_id        ${ \( $_[0]->element('doc_id_sql_type')->get() ) },
  action        INT2,
  text          TEXT,
  _sq           SERIAL )";
}

sub sql_textsearch_word_lock {
#   my ( $index, $i_table_name, $word ) = @_;
#   my $dbh = $index->get_dbh();
#   $dbh->{AutoCommit}=0;
#   $dbh->commit();
#   my $sth = $dbh->prepare
#     ( "LOCK TABLE $i_table_name IN SHARE ROW EXCLUSIVE MODE" );
#   $sth->execute();
#   $sth->finish();
}

sub sql_textsearch_word_unlock {
#   my ( $index, $i_table_name, $word ) = @_;
#   my $dbh = $index->get_dbh();
#   #my $q_lock_name = $dbh->quote ( $i_table_name . $word );
#   $dbh->commit();
#   $dbh->{AutoCommit}=1;
#   #$dbh->do ( "COMMIT WORK" );
}


sub sql_index_only_doc_id_type {
  return 'BLOB';
}


# yech. should we be trying to use the non-standard array *= operators
# in postgres to do this textsearch stuff?
sub sql_textsearch_pack_seq_list {
  shift();
  #return MIME::Base64::encode_base64( pack("L*", @_), '' );
  return join ( '-', @_ ) . '-';
}

sub sql_textsearch_unpack_seq_list {
  #return unpack ( "L*", MIME::Base64::decode_base64($_[1]) );
  chop ( $_[1] );
  return split ( '-', $_[1] );
}


# SQLite needs to do these the hard way -- creating a temp table and
# stuff. there is no difference between drop and modify, in the
# mechanics, and the field_name and field_type variables are not used
# (the def fields are pulled instead).
sub sql_alter_data_table_drop_or_modify {
  my $index = shift;
  $index->sql_alter_by_recreating();
}

sub sql_alter_data_table_add            {
  my $index = shift;
  $index->sql_alter_by_recreating();
}

sub sql_alter_data_table_add_collection {
  my $index = shift;
  $index->sql_alter_by_recreating();
}

#sub sql_alter_data_table_add_index      {
#  die "unimplemented";
#}

#sub sql_alter_data_table_drop_index     {
#  die "unimplemented";
#}

sub sql_data_table_name {
  my $index = shift();
  $index->ping();
  my $dbh = $index->get_dbh();  
  my $sth = $dbh->prepare_cached (
    qq[
        SELECT table_name FROM index_tables 
          WHERE doctype  = ? 
          AND index_name = ? 
          AND table_type = ? 
    ]);
  dbg 'data_table_name', $index->doctype() .
      $index->element('name')->get() .
      XML::Comma::Indexing::Index->DATA_TABLE_TYPE();
  $sth->execute( $index->doctype(), $index->element('name')->get(), 
                 XML::Comma::Indexing::Index->DATA_TABLE_TYPE() );
  my $result = $sth->fetchrow_arrayref();
  $sth->finish();
  return $result ? $result->[0] : die "FIX: no data table name found\n";
}

sub sql_data_table_definition {
  my ($index, $name) = @_;
  $index->sql_begin_data_table_definition( $name ) .
         $index->sql_end_data_table_definition();
}

sub sql_new_data_table_definition {
  my ( $index, $name ) = @_;
  my $sql = $index->sql_begin_data_table_definition( $name ) .
            $index->sql_columns_from_index_data_table_definition() . 
            $index->sql_end_data_table_definition();
  return $sql;
}

sub sql_begin_data_table_definition {
  my ($index, $name) = @_;
  my $doc_id_type = $index->element('doc_id_sql_type')->get();
  return 
  qq[
      CREATE TABLE $name (
        _comma_flag             TINYINT,
        record_last_modified    INT,
        _sq                     INTEGER PRIMARY KEY,
        doc_id                  $doc_id_type
    ];
}

sub sql_columns_from_index_data_table_definition {
  my $index = shift;
  my $sql_chunk;
  
  # standard index fields
  foreach my $field ( $index->elements('field') ) {
    $sql_chunk .= ", " . $field->element('name')->get() . " " .
                  $field->element('sql_type')->get();
  }
  
  # multi-index stuff
  $sql_chunk .= ", store VARCHAR(255) NOT NULL" if
    $index->element('store')->get();
  $sql_chunk .= ", doctype VARCHAR(255) NOT NULL" if 
    $index->element('doctype')->get();
  
  # collections
  foreach my $coll ( $index->elements( 'collection' ), 
                   $index->elements( 'sort' ) )        {
    my $type = $coll->element('type')->get();
    next if $type eq 'many_tables';
    my $name = $coll->element('name')->get();    
    if ( $type eq 'stringified' ) {
      $sql_chunk .= " ,$name TEXT"; 
    } 
  }
  dbg 'data_table_from_index', $sql_chunk;
  return $sql_chunk;
}

sub sql_drop_bcollection_table {
  my ( $index, $collection_name ) = @_;
  $index->ping();
  my $dbh = $index->get_dbh();
  my $sth = $dbh->prepare ( "SELECT table_name FROM index_tables WHERE collection=${ \( $dbh->quote($collection_name) ) } AND doctype=${ \( $dbh->quote($index->doctype()) )}" );
  $sth->execute();
  while ( my $row = $sth->fetchrow_arrayref() ) {
    my $table_name = $row->[0];
    my $sth = $dbh->prepare ( "DROP TABLE $table_name" );
    $sth->execute();
    $sth->finish();
    
    $index->ping();
    $dbh = $index->get_dbh();
    $sth = $dbh->prepare ( "DELETE FROM index_tables WHERE table_name=${ \( $dbh->quote($table_name) ) }" );
    $sth->execute();
    $sth->finish();
  }
}

sub sql_end_data_table_definition {
  return qq[ ) ];
}

sub sql_create_data_table {
  my ( $index, $existing_table_name ) = @_;
  return $index->sql_create_a_table
    ( table_type          => XML::Comma::Indexing::Index->DATA_TABLE_TYPE(),
      index_def           => $index->to_string(),
      table_def_sub       => 'sql_data_table_definition',
      existing_table_name => $existing_table_name );
}

sub sql_alter_by_recreating {
  my $index  = shift;
  my $temp_table_name = "t$$" . '_' . int(rand(0xffffffff));
  my $data_table_name = $index->data_table_name();

  dbg "altering", $data_table_name;
  $index->ping();
  my $dbh = $index->get_dbh();
  my $sth = $dbh->prepare( 
    "CREATE TABLE $temp_table_name AS SELECT * FROM $data_table_name"
  );
  $sth->execute();
  $sth->finish();  
  
  $index->ping();
  $dbh = $index->get_dbh();
  $sth = $dbh->prepare( "DROP TABLE $data_table_name" );
  $sth->execute();
  $sth->finish();

  # SQLite seems to remember the table schema that we dropped unless we
  # explicitly disconnect and reconnect.  XXX re-read documentation.
  $index->reconnect();
  $index->create_new_data_table ( $data_table_name );
  
  # The SQLite driver doesn't support column_info, and unless I missed 
  # something in the DBI docs (which is likely), we have to do 
  # a successful fetchrow_hashref in order to get at the column names.
  # This is so sqlite won't complain about a column mis-match with the 
  # INSERT INTO ... SELECT FROM ... below
  $index->ping();
  $dbh = $index->get_dbh();
  $sth = $dbh->prepare( "SELECT * FROM $temp_table_name LIMIT 1" );
  $sth->execute();
  my $col_ref = $sth->fetchrow_hashref();

  # only if the previous select returned a row
  if ( $col_ref ) {
    my $col_string = join ", ", keys %{ $col_ref };

    $index->ping();
    $dbh = $index->get_dbh();
    $sth = $dbh->prepare (
    "INSERT INTO $data_table_name ( _comma_flag, doc_id, record_last_modified, _sq, ${ \( join(', ',$index->columns()) ) } ) SELECT $col_string FROM $temp_table_name"
           );
    $sth->execute();
    $sth->finish();
  }

  $index->ping();
  $dbh = $index->get_dbh();
  $sth = $dbh->prepare ( "DROP TABLE $temp_table_name" );
  $sth->execute();
  $sth->finish();
  return '';
}

sub create_new_data_table {
  my ( $index, $table_name ) = @_;
  return $index->sql_create_a_table
    ( table_type          => XML::Comma::Indexing::Index->DATA_TABLE_TYPE(),
      index_def           => $index->to_string(),
      table_def_sub       => 'sql_new_data_table_definition',
      existing_table_name => $table_name );
}

#  table_type => const for the table_type column
#  table_def_sub => string of sub name to call to get table def
#  existing_table_name => pass this to *re_create* a table under old name
#  index_def => string for index_def column (if any)
#  sort_spec => string for sort_spec column (if any)
#  textsearch => string for text_search column (if any)
#  collection => name of collection being binary indexed (if any)
sub sql_create_a_table {
  my ($index, %arg) = @_;
  my $sort_spec  = $arg{sort_spec}  || '';
  my $textsearch = $arg{textsearch} || '';
  my $collection = $arg{collection} || '';
  my $index_def  = $arg{index_def}  || '';
  my $table_type = $arg{table_type} || '';
  my $name;
  my $table_def_sub = $arg{table_def_sub} || die "need table def sub";

  my $dbh;

  dbg 'create_a_table', "using $table_def_sub";
  if ( ! $arg{existing_table_name} ) {
    # add an appropriate line to the index table
    $index->ping();
    $dbh = $index->get_dbh();
    my $sth = $dbh->prepare_cached ( 
      qq[ 
          INSERT INTO index_tables ( doctype, index_name, last_modified, 
                                     _comma_flag, index_def, sort_spec, 
                                     textsearch, collection, table_type ) 
            VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ? )
      ]);
    $sth->execute ( $index->doctype(), $index->element('name')->get(),
                    time(), 0, $index_def, $sort_spec, $textsearch, 
                    $collection, $table_type );
    $sth->finish();

    # make a name for that table
    my $stub = substr ( $index->doctype(), 0, 8 ); 
    $index->ping();
    $dbh = $index->get_dbh();
    $sth = $dbh->prepare_cached ( 
      qq[
          SELECT _sq FROM index_tables 
            WHERE doctype = ? 
              AND index_name = ? 
              AND table_type = ?
              AND index_def  = ? 
              AND sort_spec  = ?
              AND textsearch = ?
              AND collection = ?
      ]);
    $sth->execute ( $index->doctype(), $index->element('name')->get(),
                    $table_type, $index_def, $sort_spec, 
                    $textsearch, $collection );
    my $s = $sth->fetchrow_arrayref()->[0];
    $sth->finish();
    $name = $stub . '_' . sprintf ( "%04s", $s );
    my $q_t_name = $dbh->quote ( $name );
    $index->ping();
    $dbh = $index->get_dbh();
    $sth = $dbh->prepare_cached (
      qq[
          UPDATE index_tables 
            SET table_name = $q_t_name 
            WHERE _sq = $s 
      ]);
    $sth->execute();
    $sth->finish();
  } else {
    $name = $arg{existing_table_name};
  }

  $index->ping();
  $dbh = $index->get_dbh();
  
  # XXX
  $index->reconnect();
  $dbh = $index->get_dbh();
  
  # now make the table
  eval {
    my $sth = $dbh->prepare_cached ( $index->$table_def_sub( $name, %arg ) );
    $sth->execute();
    $sth->finish();
  };
  if ( $@ ) {
    XML::Comma::Log->err( 
      "couldn't create database table ($table_def_sub). DB says: $@\n"
    );
  }
  return $name;
}

sub sql_insert_into_data {
  my ( $index, $doc, $comma_flag ) = @_;
  $comma_flag ||= 0;

  # the normal case is to treat the doc's doc_id as a nearly-normal
  # field, getting its value straight from the doc. but there is a
  # special case where we want the doc_id to get its value here,
  # during the write, from the _sq number.
  my ( $doc_make_id_flag, $doc_id ) = ( undef, $doc->doc_id() );
  dbg 'doc_id', $doc_id;
  if ( $doc->doc_id() eq 'COMMA_DB_SEQUENCE_SET' ) {
    $doc_id = "0";
    $doc_make_id_flag = 1;
  };

  $index->ping(); 
  my $dbh        = $index->get_dbh();
  my $data_table = $index->data_table_name();
 
  # With SQLite, we are responsible for maintaining the SERIAL 
  # equivalent for _sq.  If this is our first _sq for this table,
  # int-ify it so the later select max(_sq) +1 on insert will work
  
  # my $sth = $dbh->prepare_cached( "SELECT max(_sq) from $data_table" );
  # $sth->execute();
  
  # my $first_sq = 1 unless $sth->fetchrow_arrayref->[0];
  # $sth->finish();

  # the core logic -- insert the row into the data table with all
  # columns properly filled

  my @columns = $index->columns();
  my $columns_list = join ( ',', @columns );
  dbg 'columns_list', $columns_list;

  my @columns_values = map { $index->column_value($_, $doc,) } @columns;
  my $placeholders = join( ", ", ('?') x @columns_values );

  # my $sql_string;
  # if ( $first_sq ) {
  #   $sql_string  = 
  #    qq[
  #      INSERT INTO $data_table
  #          ( _sq, doc_id,  _comma_flag, record_last_modified, $columns_list ) 
  #        VALUES 
  #          ( 1, $doc_id, ?, ?, $placeholders )
  #      ];
  # } else {
  my $sql_string  =
      qq[
        INSERT INTO $data_table
            ( _sq, doc_id, _comma_flag, record_last_modified, $columns_list ) 
          VALUES 
            ( NULL, ?, ?, ?, $placeholders )
        ];
  dbg 'sql', $sql_string;
  $index->ping();
  $dbh = $index->get_dbh();
  my $sth = $dbh->prepare_cached ( $sql_string ); 
  dbg 'placeholders', $doc_id, $comma_flag, time(), @columns_values;
  $sth->execute($doc_id, $comma_flag, time(), @columns_values );
  $sth->finish();

  # and, finally set the id field correctly, both in the db and in the
  # doc, if we're responsible for generating the id. CAVEAT: we only
  # set the 'id' info in the doc -- some caller up the chain should
  # take responsibility for making all of the doc's storage_info stuff
  # right.
  if ( $doc_make_id_flag ) {
    $index->ping();
    $dbh = $index->get_dbh();
    $sth = $dbh->prepare_cached ( 
      qq[
          SELECT _sq FROM $data_table 
          WHERE doc_id = ? 
      ]);
    dbg 'doc_id', $doc_id;
    $sth->execute( $doc_id );
    $doc_id = $sth->fetchrow_arrayref->[0];
    dbg 'doc_id', $doc_id;
    $sth->finish();

    $index->ping();
    $dbh = $index->get_dbh();
    $sth = $dbh->prepare_cached ( 
      qq[
          UPDATE $data_table SET doc_id = ?
          WHERE _sq = ?
      ]);
    $sth->execute( $doc_id, $doc_id );
    $sth->finish();
    $doc->set_storage_info ( undef, undef, $doc_id );
  }
}

# this update w/ subselect ought to work, but Pg won't allow the order
# by in the subselect. maybe oracle?
#
#
#  # args: index, table_name, order_by, size_limit
#  sub sql_set_comma_flags {
#    my ( $index, $table_name, $order_by, $size_limit ) = @_;
#    my $data_table_name = $index->data_table_name();
#    my $dbh = $index->get_dbh();
#    my $sel = $dbh->do
#   ("UPDATE $table_name SET _comma_flag=1 WHERE doc_id IN
#     (SELECT S.doc_id FROM $table_name AS S, $data_table_name AS D
#      WHERE S.doc_id = D.doc_id ORDER BY D.$order_by LIMIT $size_limit)");
#  }


sub sql_create_bcollection_table {
  my ( $index, $collection_name, $bcoll_el ) = @_;
  return $index->sql_create_a_table
    ( table_type    => XML::Comma::Indexing::Index->BCOLLECTION_TABLE_TYPE(),
      table_def_sub => 'sql_bcollection_table_definition',
      collection    => $collection_name,
      bcoll_el      => $bcoll_el );
}

sub sql_clean_find_orphans {
  my ( $table_name, $data_table_name ) = @_;
  return "SELECT $table_name.doc_id FROM $table_name WHERE $table_name.doc_id NOT IN (SELECT $data_table_name.doc_id FROM $data_table_name)";
}

sub sql_limit_clause {
  my ( $index, $limit_number, $limit_offset ) = @_;
  if ( $limit_number ) {
    if ( $limit_offset ) {
      return " LIMIT $limit_number OFFSET $limit_offset";
    } else {
      return " LIMIT $limit_number";
    }
  } else {
    return '';
  }
}

#  sub sql_create_textsearch_temp_table {
#    my ( $index, $ts_index_table_name, $word ) = @_;
#    my $dbh = $index->get_dbh();
#    my $packed =
#      $index->sql_get_textsearch_index_packed ( $ts_index_table_name, $word );

#    my $temp_table_name;
#    my $count;

#    if ( $packed ) {
#      $temp_table_name = '_temp_' . $$ . '_' . int(rand(0xffffff));
#      $dbh->do ( "CREATE TEMPORARY TABLE $temp_table_name ( id VARCHAR(255) PRIMARY KEY )" );
#      my %seen;
#      foreach ( $index->sql_textsearch_unpack_seq_list($packed) ) {
#        $count++;
#        next if $seen{$_}++;
#        my $value = $dbh->quote ( $_ );
#        $dbh->do ( "INSERT INTO $temp_table_name (id) VALUES ($value)" );
#      }
#    } else {
#      return ('',0);
#    }
#    #dbg 'tt/s', $temp_table_name, $count;
#    return ( $temp_table_name, $count );
#  }

sub sql_create_textsearch_temp_table_stmt {
  my ( $index, $dbh ) = @_;
  my $temp_table_name = '_temp_' . $$ . '_' . int(rand(0xffffffff));
  $dbh->do ( "CREATE TEMPORARY TABLE $temp_table_name ( id VARCHAR(255) PRIMARY KEY )" );
  return $temp_table_name;
}

sub sql_load_data {
  my ( $index, $dbh, $temp_table_name, $temp_filename ) = @_;
  $dbh->do ( "COPY $temp_table_name FROM '$temp_filename'" );
}

sub ping {
  my $self = shift();

  dbg 'ping from sqlite', $self->get_dbh();
  my $dbh = $self->get_dbh_reader();
  my $sth;
  # assume comma_hold is already set up
  eval {
    $sth = $dbh->prepare_cached( "SELECT key FROM comma_hold LIMIT 1" );
    $sth->execute();
    $sth->finish();
  };
  if ( $@ ) {
    return $self->reconnect();
  }
  return 1;
}

# aped from DBH_User's _connect.  I don't like the code duplication, 
# but we don't want to run the connect_check method, and we don't
# want to sleep after the disconnect as this is called routinely.
sub reconnect {
  my $self = shift;
  # try to deal nicely with a currently-connected handle (which we may
  # have inherited from a fork, etc.
  eval { $self->{_DBH}->disconnect(); sleep 1; };
  my $db_struct = $self->db_struct();
  my @connect_array = @{ $db_struct->{dbi_connect_info} };

  # try to connect -- looping to try again if we fail
  my $max_attempts = 30;
  for my $attempt ( 1 .. $max_attempts ) {
    eval { $self->{_DBH} = DBI->connect( @connect_array ); };
    last  unless  $@;
    if ( $attempt < $max_attempts ) {
      XML::Comma::Log->warn ( 'Couldn\'t connect to database ' .
                              "(attempt $attempt) -- $@" );
      sleep 2;
    } else {
      XML::Comma::Log->err ( 'DB_CONNECTION_ERROR', "$@" );
    }
  }
  dbg 'reconnect', $self->{_DBH};
  $self->{_DBH_pid} = $$;
  return $self->{_DBH};
}

sub sql_textsearch_cat_seq_list {
  die "TODO: steal SQLite.pm::sql_textsearch_cat_seq_list, and pack/unpack from Pg.pm";
}

1;


