##
#
#    Copyright 2001, AllAfrica Global Media
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

package XML::Comma::SQL::Base;

use XML::Comma::Storage::Util ();
use XML::Comma::Util qw( dbg );
use Sys::Hostname ();

use strict;

sub sql_create_lock_table {
  my $lock = shift;
  my $dbh  = $lock->get_dbh_writer();
  # if database is postgres, we b0rked our cursor when we tried to access 
  # the non-existent comma_lock table... eval{} is in case we have an old
  # version of DBD::Pg that doesn't support transactions
  eval { $dbh->rollback() if(XML::Comma->system_db() eq 'postgres'); };
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
  die "sql_create_hold_table is not implemented";
}

# $lock, $key
sub sql_get_lock_record {
  my ($lock, $key) = @_;
  my $dbh  = $lock->get_dbh_writer();
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
    die "$@\n";
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
  die "sql_get_hold unimplemented";
}

sub sql_release_hold {
  die "sql_release_hold unimplemented";
}

#
# --------------------------------
#


sub sql_create_index_tables_table {
  die "sql_create_index_tables_table unimplemented";
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
  my $dbh = $index->get_dbh_writer();
  my $sort_spec  = $arg{sort_spec}  || '';
  my $textsearch = $arg{textsearch} || '';
  my $collection = $arg{collection} || '';
  my $index_def  = $arg{index_def}  || '';
  my $table_type = $arg{table_type} || '';
  my $name;
  my $table_def_sub = $arg{table_def_sub} || die "need table def sub";

  if ( ! $arg{existing_table_name} ) {
    # add an appropriate line to the index table
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
    $sth = $dbh->prepare_cached (

      qq[
          UPDATE index_tables 
            SET table_name = ? 
            WHERE _sq = ?
      ]);
    $sth->execute( $name, $s );
    $sth->finish();
  } else {
    $name = $arg{existing_table_name};
  }

  # now make the table
  eval {
    my $sth = $dbh->prepare_cached ( $index->$table_def_sub( $name, %arg ) );
    $sth->execute();
    $sth->finish();
  };
  if ( $@ ) {
    die "couldn't create database table ($table_def_sub). DB says: $@\n";
  }
  return $name;
}

sub sql_create_data_table {
  my ( $index, $existing_table_name ) = @_;
  return $index->sql_create_a_table
    ( table_type          => XML::Comma::Indexing::Index->DATA_TABLE_TYPE(),
      index_def           => $index->to_string(),
      table_def_sub       => 'sql_data_table_definition',
      existing_table_name => $existing_table_name );
}

sub sql_data_table_definition {
  die "sql_data_table_definition is not implemented";
}

sub sql_data_table_name {
  my $index = shift();
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached (
    qq[
        SELECT table_name FROM index_tables 
          WHERE doctype  = ? 
          AND index_name = ? 
          AND table_type = ? 
    ]);
  $sth->execute( $index->doctype(), $index->element('name')->get(), 
                 XML::Comma::Indexing::Index->DATA_TABLE_TYPE() );
  my $result = $sth->fetchrow_arrayref();
  $sth->finish();
  return $result ? $result->[0] : die "FIX: no data table name found\n";
}


sub sql_get_def {
  my $index = shift();
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ 
        SELECT index_def FROM index_tables 
          WHERE doctype  = ?
          AND index_name = ?
          AND table_type = ?
    ]);
  $sth->execute( $index->doctype(), $index->element('name')->get(), 
                 $index->DATA_TABLE_TYPE() );
  my $result = $sth->fetchrow_arrayref();
  $sth->finish();
  return $result ? $result->[0] : '';
}

sub sql_update_def_in_tables_table {
  my $index = shift();
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[
        UPDATE index_tables 
          SET index_def = ?
          WHERE table_name = ?
    ]);
  $sth->execute( $index->to_string(), $index->data_table_name() );
  $sth->finish();
}


# handles drop or modify. if there is a third arg, we assume that's a
# column type, and this is a modify.
sub sql_alter_data_table_drop_or_modify {
  my ( $index, $field_name, $field_type ) = @_;
  my $dbh        = $index->get_dbh_writer();
  my $data_table = $index->data_table_name();
  if ( $field_type ) {
    my $sth = $dbh->prepare_cached ( 
      qq[
          ALTER TABLE $data_table
              MODIFY $field_name $field_type
      ]);
    $sth->execute();
    $sth->finish();
  } else {
    my $sth = $dbh->prepare_cached ( 
      qq[
          ALTER TABLE $data_table
            DROP $field_name
      ]);
    $sth->execute();
    $sth->finish();
  }
}

sub sql_alter_data_table_add {
  my ( $index, $field_name, $field_type ) = @_;
  my $dbh        = $index->get_dbh_writer();
  my $data_table = $index->data_table_name();
  my $sth = $dbh->prepare_cached (
    qq[
        ALTER TABLE $data_table
            ADD $field_name $field_type
    ]);
  $sth->execute();
  $sth->finish();
}

sub sql_alter_data_table_change_primary_key {
  my ( $index, @fields ) = @_;
  my $dbh        = $index->get_dbh_writer();
  my $data_table = $index->data_table_name();

  my $new_key;
  unless ( XML::Comma->system_db() eq 'postgres' ) {
    if ( $index->doc_id_sql_type =~ /\((\d+)\)/ ) {
      $new_key = "doc_id($1), ";
    } else {
      $new_key = "doc_id(100), ";
    }
    $new_key .= join ", ", map { "$_(100)" } @fields;
  } else { # postgres
    $new_key = join ", ", ( 'doc_id', @fields );
  }
  
  my $sth;
  if(XML::Comma->system_db() eq 'postgres') {
    $sth = $dbh->prepare_cached (
      qq [
          ALTER TABLE ${data_table}
              DROP CONSTRAINT ${data_table}_pkey
      ]);
  } else {
    $sth = $dbh->prepare_cached ( 
      qq[ 
          ALTER TABLE $data_table
              DROP PRIMARY KEY
      ]);
  }

  $sth->execute();
  $sth->finish();

  $sth = $dbh->prepare_cached ( 
    qq[
        ALTER TABLE $data_table
            ADD PRIMARY KEY ( $new_key )
    ]);
  $sth->execute();
  $sth->finish();
}

sub sql_alter_data_table_add_collection {
  my ( $index, $field_name ) = @_;
  my $dbh        = $index->get_dbh_writer();
  my $data_table = $index->data_table_name();
  my $sth = $dbh->prepare_cached (
    qq[
        ALTER TABLE $data_table
            ADD $field_name TEXT
    ]);
  $sth->execute();
  $sth->finish();
}

sub sql_alter_data_table_add_index {
  my ( $index, $sql_index ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $unique = ( $sql_index->element('unique')->get() ? 'UNIQUE' : '' );
  my $fields = $sql_index->element( 'fields' )->get();
  my $sql_index_name = $sql_index->element('name')->get() ||
    die "sql_index must have a name\n";
  my $data_table = $index->data_table_name();
  my $sth = $dbh->prepare_cached ( 
    qq[
        CREATE $unique INDEX $sql_index_name 
          ON $data_table ($fields)
    ]);
  $sth->execute();
  $sth->finish();
}

sub sql_alter_data_table_drop_index {
  my ( $index, $sql_index ) = @_;
  my $dbh        = $index->get_dbh_writer();
  my $data_table = $index->data_table_name();
  eval {
    my $sth = $dbh->prepare_cached ( 
      qq[
          DROP INDEX $sql_index ON $data_table
      ]);
    $sth->execute();
    $sth->finish();
  }; if ( $@ ) {
    XML::Comma::Log->warn ( "warning: couldn't drop index $_[1]" );
  }
}

sub sql_insert_into_data {
  my ( $index, $doc, $comma_flag ) = @_;
  $comma_flag ||= 0;

  # the normal case is to treat the doc's doc_id as a nearly-normal
  # field, getting its value straight from the doc. but there is a
  # special case where we want the doc_id to get its value here,
  # during the write, from the _sq number.
  my ( $doc_make_id_flag, $doc_id ) = ( undef, $doc->doc_id() );
  #dbg 'insert_into_data', $doc_id;
  if ( $doc->doc_id() eq 'COMMA_DB_SEQUENCE_SET' ) {
    $doc_id = 0;
    $doc_make_id_flag = 1;
  };

  # the core logic -- insert the row into the data table with all
  # columns properly filled
  my $dbh        = $index->get_dbh_writer();
  my $data_table = $index->data_table_name();

  my @columns = $index->columns();
  my $columns_list = join ( ',', 'doc_id', @columns );

  my @columns_values = $doc_id;
  push @columns_values, map { $index->column_value($_, $doc,) } @columns;
  my $placeholders = join( ", ", ('?') x @columns_values );

  # dbg 'sql', $string;
  my $sth = $dbh->prepare_cached ( 
    qq[
        INSERT INTO $data_table
            ( _comma_flag, record_last_modified, $columns_list ) 
          VALUES 
            ( ?, ?, $placeholders )
    ]);
  #dbg 'columns', @columns_values;
  $sth->execute($comma_flag, time(), @columns_values );
  $sth->finish();

  # and, finally set the id field correctly, both in the db and in the
  # doc, if we're responsible for generating the id. CAVEAT: we only
  # set the 'id' info in the doc -- some caller up the chain should
  # take responsibility for making all of the doc's storage_info stuff
  # right.
  if ( $doc_make_id_flag ) {
    $sth = $dbh->prepare_cached ( 
      qq[
          SELECT _sq FROM $data_table 
          WHERE doc_id = ? 
      ]);
    $sth->execute( $doc_id );
    $doc_id = $sth->fetchrow_arrayref->[0];
    $sth->finish();

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

sub sql_update_in_data {
  my ( $index, $doc, $comma_flag ) = @_;
  $comma_flag = $comma_flag || 0;
  my $dbh = $index->get_dbh_writer();
  my $data_table = $index->data_table_name();

  my $columns_sets = join 
    ( ',', "_comma_flag = ?",
      "record_last_modified = ?",
      map {
        $_ . '=' . ' ?'
      } $index->columns() );

  my $where = $index->sql_get_where_pk( $doc );

  my $sth = $dbh->prepare_cached ( 
    qq[
        UPDATE $data_table
        SET $columns_sets 
            $where
    ]);
  $sth->execute( $comma_flag, time(), 
                 ( map { $index->column_value($_,$doc) } $index->columns() ));
  $sth->finish();
}

sub sql_delete_from_data {
  my ( $index, $doc ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $data_table = $index->data_table_name();
  my $where = $index->sql_get_where_pk( $doc );
  my $sth = $dbh->prepare_cached ( 
    qq[
        DELETE FROM $data_table
          $where
    ]);
  $sth->execute();
  $sth->finish();
}

# TODO: come back here and work some trickery to return a statement with 
# placeholders? 
sub sql_get_where_pk {
  my ( $index, $doc ) = @_;
  my $dbh = $index->get_dbh_writer();
  my %key_fields;
  @key_fields{ qw( doctype store id ) } = map { $dbh->quote( $_ ) } 
    XML::Comma::Storage::Util->split_key( $doc->doc_key() );
  my $sql = "WHERE doc_id = " . $key_fields{ id };
  foreach my $extra ( @{ $index->{ _Index_extra_pk_fields } } ) {
    $sql .= " AND $extra = " . $key_fields{ $extra };
  }
  return $sql;
}

sub sql_create_sort_table {
  my ( $index, $sort_spec ) = @_;
  return $index->sql_create_a_table
    ( table_type    => XML::Comma::Indexing::Index->SORT_TABLE_TYPE(),
      table_def_sub => 'sql_sort_table_definition',
      sort_spec     => $sort_spec );
}

sub sql_sort_table_definition {
  die "sql_sort_table_definition is not implemented";
}

sub sql_get_sort_table_for_spec {
  my ( $index, $sort_spec ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[
        SELECT table_name FROM index_tables 
            WHERE doctype  = ? 
            AND index_name = ?
            AND sort_spec  = ?
    ]);
  $sth->execute( $index->doctype(), $index->element('name')->get(), 
                 $sort_spec );
  my $result = $sth->fetchrow_arrayref();
  $sth->finish();
  return  $result ? $result->[0] : '';
}

sub sql_get_sort_spec_for_table {
  my ( $index, $table_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached (
    qq[
        SELECT sort_spec FROM index_tables 
          WHERE table_name = ?
    ]);
  $sth->execute( $table_name );
  my $result = $sth->fetchrow_arrayref();
  $sth->finish();
  return  $result ? $result->[0] : '';
}

# sort_name is optional -- if not given, just returns all sort tables
sub sql_get_sort_tables {
  my ( $index, $sort_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sql = 
    qq[
        SELECT table_name FROM index_tables 
          WHERE doctype  = ? 
          AND index_name = ? 
          AND table_type = ? 
      ];
  $sql .= $sort_name ? qq[ AND sort_spec LIKE ? ] : '';
  my $sth = $dbh->prepare_cached ( $sql );
  my @values = ( $index->doctype(), $index->element('name')->get(),
                 $index->SORT_TABLE_TYPE );
  push @values, $index->make_sort_spec( $sort_name, '' ) . '%' if $sort_name;
  $sth->execute( @values );
  return map { $_->[0] } @{$sth->fetchall_arrayref()};
}


sub sql_insert_into_sort {
  my ( $index, $doc_id, $sort_table_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[
        INSERT INTO $sort_table_name ( _comma_flag, doc_id ) 
          VALUES ( ?, ? )
      ]
  );
  $sth->execute( 0, $doc_id );
  $sth->finish();
}

# returns the number of rows deleted
sub sql_delete_from_sort {
  my ( $index, $doc_id, $sort_table_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ DELETE FROM $sort_table_name WHERE doc_id = ? ] );
  $sth->execute( $doc_id );
  $sth->finish();
}

sub sql_create_bcollection_table {
  my ( $index, $collection_name, $bcoll_el ) = @_;
  return $index->sql_create_a_table
    ( table_type    => XML::Comma::Indexing::Index->BCOLLECTION_TABLE_TYPE(),
      table_def_sub => 'sql_bcollection_table_definition',
      collection    => $collection_name,
      bcoll_el      => $bcoll_el );
}

sub sql_bcollection_table_definition {
  die "sql_bcollection_table_definition is not implemented";
}

sub sql_drop_bcollection_table {
  my ( $index, $collection_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ SELECT table_name 
          FROM index_tables 
          WHERE collection = ?
          AND doctype      = ?
      ]
  );
  $sth->execute( $collection_name, $index->doctype() );
  while ( my $row = $sth->fetchrow_arrayref() ) {
    my $table_name = $row->[0];
    my $sth = $dbh->prepare_cached ( qq[ DROP TABLE $table_name ] );
    $sth->execute();
    $sth->finish();
    $sth = $dbh->prepare_cached ( 
      qq[
          DELETE FROM index_tables 
            WHERE table_name = ? 
        ]
    );
    $sth->execute( $table_name );
    $sth->finish();
  }
}

# name is optional -- if not given, returns all bcollection table names
sub sql_get_bcollection_table {
  my ( $index, $name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sql = 
    qq[
        SELECT table_name 
          FROM index_tables 
          WHERE doctype  = ? 
          AND index_name = ? 
          AND table_type = ?
     ];
  $sql .= qq[ AND collection = ? ] if $name;
  my @values = ( $index->doctype(), $index->element('name')->get(),
                 $index->BCOLLECTION_TABLE_TYPE );
  push @values, $name if $name;
  my $sth = $dbh->prepare_cached ( $sql );
  $sth->execute( @values );
  my $result = $sth->fetchall_arrayref();
  if ( wantarray ) {
    return map { $_->[0] } @{$result};
  } else {
    return $result->[0]->[0] || '';
  }
}

sub sql_insert_into_bcollection {
  my ( $index, $table_name, $doc_id, $col_str, $col_extra ) = @_;
  my $dbh = $index->get_dbh_writer();
  if ( $col_extra ) {
    my $sth = $dbh->prepare_cached ( 
      qq[
          INSERT INTO $table_name ( _comma_flag, doc_id, value, extra ) 
            VALUES ( ?, ?, ?, ? )
        ]
    );
    $sth->execute( 0, $doc_id, $col_str, $col_extra );
    $sth->finish();
  } else {
    my $sth = $dbh->prepare_cached (
      qq[
          INSERT INTO $table_name ( _comma_flag, doc_id, value ) 
            VALUES ( ?, ?, ? )
        ]
    );
    $sth->execute( 0, $doc_id, $col_str );
    $sth->finish();
  }
}

sub sql_get_values_from_bcollection {
  my ( $index, $doc_id, $table_name ) = @_;
  my $dbh = $index->get_dbh_reader();
  my $sth = $dbh->prepare_cached ( 
    qq[ SELECT value FROM $table_name WHERE doc_id = ? ] 
  );
  $sth->execute( $doc_id );
  return map { $_->[0] } @{ $sth->fetchall_arrayref() };
}

sub sql_delete_from_bcollection {
  my ( $index, $doc_id, $table_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ DELETE FROM $table_name WHERE doc_id = ? ] 
  );
  $sth->execute( $doc_id );
  $sth->finish();
}

sub sql_create_textsearch_tables {
  my ( $index, $textsearch ) = @_;
  $index->sql_create_a_table
    ( table_type => XML::Comma::Indexing::Index->TEXTSEARCH_INDEX_TABLE_TYPE(),
      table_def_sub       => 'sql_textsearch_index_table_definition',
      textsearch          => $textsearch->element('name')->get() );
  $index->sql_create_a_table
    ( table_type => XML::Comma::Indexing::Index->TEXTSEARCH_DEFERS_TABLE_TYPE(),
      table_def_sub       => 'sql_textsearch_defers_table_definition',
      textsearch          => $textsearch->element('name')->get() );
  return 1;
}

sub sql_textsearch_index_table_definition {
  die "sql_textsearch_index_table_definition is not implemented";
}

sub sql_textsearch_defers_table_definition {
  die "sql_textsearch_defers_table_definition is not implemented";
}


sub sql_drop_textsearch_tables {
  my ( $index, $textsearch_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ 
        SELECT table_name 
          FROM index_tables 
          WHERE doctype  = ? 
          AND textsearch = ? 
      ]
  );
  $sth->execute( $index->doctype(), $textsearch_name );
  while ( my $row = $sth->fetchrow_arrayref() ) {
    my $table_name = $row->[0];
    my $sth = $dbh->prepare_cached ( "DROP TABLE $table_name" );
    $sth->execute();
    $sth->finish();
    $sth = $dbh->prepare_cached ( 
      qq[
          DELETE FROM index_tables 
            WHERE table_name = ? 
        ]
    );
    $sth->execute( $table_name );
    $sth->finish();
  }
}

sub sql_get_textsearch_tables {
  my ( $index, $textsearch_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[
        SELECT table_name 
          FROM index_tables 
          WHERE doctype  = ? 
          AND textsearch = ? 
            ORDER BY table_type
      ] 
  );
  $sth->execute( $index->doctype(), $textsearch_name );
  return map { $_->[0] } @{$sth->fetchall_arrayref()};
}

sub sql_textsearch_word_lock {
  die "sql_textsearch_word_lock is not implemented";
}

sub sql_textsearch_word_unlock {
  die "sql_textsearch_word_unlock is not implemented";
}

sub sql_textsearch_pack_seq_list {
  die "sql_textsearch_pack_seq_list is not implemented";
}

sub sql_textsearch_unpack_seq_list {
  die "sql_textsearch_unpack_seq_list is not implemented";
}

# pass EITHER a single doc_id or a list of doc_seqs.
sub sql_update_in_textsearch_index_table {
  my ( $index, $i_table_name, $word, $doc_id, $clobber, @doc_seqs ) = @_;
  my $dbh = $index->get_dbh_writer();
  # generate a sequence if we were passed an id
  if ( $doc_id ) {
    @doc_seqs = ( $index->sql_get_sq_from_data_table($doc_id) );
  }
  # just return without doing anything if we turn out not to have any
  # @doc_seqs. unless we're in $clobber mode, in which case we want to
  # enter an empty record.
  return if ! @doc_seqs and ! $clobber;
  my $packed = $index->sql_textsearch_pack_seq_list ( @doc_seqs );
  $index->sql_textsearch_word_lock ( $i_table_name, $word );
  # modify row
  my $sth =$dbh->prepare_cached ( 
     qq[ SELECT seqs FROM $i_table_name WHERE word = ? ] );
  $sth->execute( $word );
  my $result = $sth->fetchrow_arrayref();
  $sth->finish();
  if ( $result ) {
    # if found, update
    my $new_seqs_string;
    if ( $result->[0] and ! $clobber ) {
      $new_seqs_string = $index->sql_textsearch_cat_seq_list($result->[0], $packed);
    } else {
      $new_seqs_string = $packed ;
    }
    my $sth = $dbh->prepare_cached (
      qq[ 
          UPDATE $i_table_name 
            SET seqs = ?
            WHERE word = ? 
        ]
    );
    $sth->execute( $new_seqs_string, $word );
    $sth->finish();
  } else {
    # else insert
    my $sth = $dbh->prepare_cached ( 
      qq[
          INSERT INTO $i_table_name ( word, seqs ) 
            VALUES ( ?, ? )
        ]
    );  
    $sth->execute( $word, $packed );
    $sth->finish();
  }
  $index->sql_textsearch_word_unlock ( $i_table_name, $word );
}

sub sql_get_sq_from_data_table {
  my ( $index, @doc_ids ) = @_;
  my @caller = caller(1);
  my @list;
  my $dbh = $index->get_dbh_writer();
  my $data_table_name = $index->data_table_name();
  foreach my $id ( @doc_ids ) {
    my $sth = $dbh->prepare_cached (
      qq[ SELECT _sq from $data_table_name WHERE doc_id = ? ]
    );
    $sth->execute( $id );
    my $result = $sth->fetchrow_arrayref();
    $sth->finish();
    push ( @list, $result->[0] )  if  $result;
  }
  return @list;
}

sub sql_delete_from_textsearch_index_table {
  my ( $index, $ts_table_name, $doc_id ) = @_;
  my ( $sq ) = $index->sql_get_sq_from_data_table( $doc_id );
  # shortcut to return if this doc isn't indexed
  return if ! $sq;
  my $packed_sq = $index->sql_textsearch_pack_seq_list ( $sq );
  # loop over all entries conatining $doc's id
  #dbg 'trying to delete', $doc_id, $ts_table_name;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ SELECT word 
          FROM $ts_table_name 
          WHERE seqs LIKE ?
      ]
  );
  $sth->execute( '%' . $packed_sq . '%' );
  while ( my $row = $sth->fetchrow_arrayref() ) {
    my $word = $row->[0];
    # get lock
    $index->sql_textsearch_word_lock ( $ts_table_name, $word );
    # fetch seqs column now that we have lock
    my $sth = $dbh->prepare_cached ( 
      qq[ SELECT seqs FROM $ts_table_name WHERE word = ? ]
    );
    $sth->execute( $word );
    my $result = $sth->fetchrow_arrayref();
    $sth->finish();
    # remove the seq in question and re-put
    my %seqs = map { $_=>1 }
      $index->sql_textsearch_unpack_seq_list ( $result->[0] );
    delete $seqs{$sq};
    my $packed_seqs = $index->sql_textsearch_pack_seq_list( keys %seqs );
    $sth = $dbh->prepare_cached (
      qq[
          UPDATE $ts_table_name 
            SET seqs   = ?
            WHERE word = ? 
        ] 
    );
    $sth->execute( $packed_seqs, $word );
    $sth->finish();
    # release lock
    $index->sql_textsearch_word_unlock ( $ts_table_name, $word );
  }
}

# DEFER DELETE ACTION CONST = 1;
# DEFER UPDATE ACTION CONST = 2;

sub sql_textsearch_defer_delete {
  my ( $index, $d_table_name, $doc_id ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ INSERT INTO $d_table_name ( doc_id, action ) 
          VALUES ( ?, ? )
      ]
  );
  $sth->execute( $doc_id, 1 );
  $sth->finish();
}

sub sql_textsearch_defer_update {
  my ( $index, $d_table_name, $doc_id, $frozen_words ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ 
        INSERT INTO $d_table_name ( doc_id, action, text ) 
          VALUES ( ?, ?, ? )
      ]
  );
  $sth->execute( $doc_id, 2, $frozen_words );
  $sth->finish();
}

sub sql_get_textsearch_defers_sth {
  my ( $index, $d_table_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ SELECT doc_id, action, _sq, text FROM $d_table_name ORDER BY _sq ]
  );
  $sth->execute();
  return $sth;
}

sub sql_delete_from_textsearch_defers_table {
  my ( $index, $d_table_name, $doc_id, $seq ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached (
    qq[ DELETE FROM $d_table_name WHERE doc_id = ? AND _sq <= ? ] 
  );
  $sth->execute( $doc_id, $seq );
  $sth->finish();
}

sub sql_get_textsearch_indexed_words {
  my ( $index, $i_table_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( qq[ SELECT word FROM $i_table_name ] );
  $sth->execute();
  return map { $_->[0] } @{$sth->fetchall_arrayref()};
}

sub sql_get_textsearch_index_packed {
  my ( $index, $i_table_name, $word ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ SELECT seqs FROM $i_table_name WHERE word = ? ]
  );
  $sth->execute( $word );
  my $result = $sth->fetchrow_arrayref();
  $sth->finish();
  return  $result ? $result->[0] : '';
}

# returns count
sub sql_key_indexed_p {
  # we have to accept the key and the id here.  doc_key() isn't available 
  # during the update() call for index only documents, and doc_id() isn't
  # enough to go on for update()'s effected by <docytpe /> and <store />
  my ( $index, $key, $ionly_id ) = @_;
  if ( ! $key ) {
    return 0 if $ionly_id eq 'COMMA_DB_SEQUENCE_SET';
    die "internal index error: update without storage info";
  }
  my ( $doctype, $store, $id ) = XML::Comma::Storage::Util->split_key( $key );
  my $AND = '';
  my @values;
  if ( $index->element('index_from_store')->get() ) {
    $AND .= qq[ AND doctype = ? AND store = ? ];
    push @values, $doctype, $store;
  }
  my $dbh = $index->get_dbh_writer();
  my $table_name = $index->data_table_name();
  my $sth = $dbh->prepare_cached ( 
    qq[ 
        SELECT count(*) from $table_name 
          WHERE doc_id = ? 
          $AND
      ]
  );
  $sth->execute( $id, @values );
  my $count = $sth->fetchrow_arrayref->[0];
  $sth->finish();
  return $count;
}

# returns count
sub sql_id_indexed_p {
  my ( $index, $id ) = @_;
  return 0 if $id eq 'COMMA_DB_SEQUENCE_SET';
  my $table_name = $index->data_table_name();
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[
        SELECT count(*) FROM $table_name 
          WHERE doc_id = ? 
      ] 
  );
  $sth->execute( $id );
  return $sth->fetchrow_arrayref->[0];
}

# returns count
sub sql_seq_indexed_p {
  my ( $index, $seq ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $table_name = $index->data_table_name();
  my $sth = $dbh->prepare_cached ( 
    qq[ SELECT count(*) FROM $table_name 
          WHERE _sq = ? 
      ]
  );
  $sth->execute( $seq );
  return $sth->fetchrow_arrayref->[0];
}

# args: $index, $table_name
sub sql_simple_rows_count {
  my ( $index, $table_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( qq[ SELECT count(*) from $table_name ] );
  $sth->execute();
  my $count = $sth->fetchrow_arrayref()->[0];
  $sth->finish();
  return $count;
}

# both drops the table and removes the index_tables entry
sub sql_drop_table {
  my ( $index, $table_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( qq[ DROP TABLE $table_name ] );
  $sth->execute();
  $sth->finish();
  $sth = $dbh->prepare_cached ( 
    qq[ 
        DELETE FROM index_tables 
          WHERE table_name = ?
      ]
  );
  $sth->execute( $table_name );
  $sth->finish();
}

sub sql_update_timestamp {
  my ( $index, $table_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached( 
    qq[
        UPDATE index_tables 
          SET last_modified = ?
          WHERE table_name  = ?
      ]
  );
  $sth->execute( time(), $table_name );
  $sth->finish();
}

# returns timestamp -- (also used to check whether a table exists)
sub sql_get_timestamp {
  my ( $index, $table_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached (
    qq[
        SELECT last_modified 
          FROM index_tables 
          WHERE table_name = ? 
      ]
  );
  $sth->execute( $table_name );
  my $result = $sth->fetchrow_arrayref();
  $sth->finish();
  return  $result ? $result->[0] : '';
}


# returns flag value
sub sql_get_table_comma_flag {
  my ( $self, $dbh, $table_name ) = @_;
  my $sth = $dbh->prepare_cached ( 
    qq[ 
        SELECT _comma_flag 
          FROM index_tables 
          WHERE table_name = ? 
      ]
  );
  $sth->execute( $table_name );
  my $result = $sth->fetchrow_arrayref();
  $sth->finish();
  return $result ? $result->[0] : '';
}

sub sql_set_table_comma_flag {
  my ( $self, $dbh, $table_name, $flag_value ) = @_;
  my $sth = $dbh->prepare_cached ( 
    qq[ UPDATE index_tables 
          SET _comma_flag  = ?
          WHERE table_name = ?
      ]
  );
  $sth->execute( $flag_value, $table_name );
  $sth->finish();
} 

sub sql_set_all_table_comma_flags_politely {
  my ( $index, $flag_value ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ 
        UPDATE index_tables 
          SET _comma_flag  = ?
          WHERE index_name = ?
          AND doctype      = ?
          AND _comma_flag  = ?
      ]
  );
  $sth->execute( $flag_value, $index->element('name')->get(), 
                 $index->doctype(), 0 );
  $sth->finish();
}

sub sql_get_all_tables_with_comma_flags_set {
  my ( $index, $ignore_flag ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[
        SELECT table_name 
          FROM index_tables 
          WHERE index_name = ?
          AND doctype      = ?
          AND ((_comma_flag != ? ) AND (_comma_flag != ? ))
      ]
  );
  $sth->execute( $index->element('name')->get(), $index->doctype(), 0,
                 $ignore_flag );
  return  map { $_->[0] } @{$sth->fetchall_arrayref()};
}

sub sql_unset_all_table_comma_flags {
  my ( $index ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ 
        UPDATE index_tables 
          SET _comma_flag = ?
          WHERE index_name = ?
          AND doctype      = ?
      ]
  );
  $sth->execute( 0, $index->element('name')->get(), $index->doctype() );
  $sth->finish();
}

sub sql_unset_table_comma_flag {
  my ( $self, $dbh, $table_name ) = @_;
  my $sth = $dbh->prepare_cached ( 
    qq[
        UPDATE index_tables 
          SET _comma_flag  = ?
          WHERE table_name = ?
      ]
  );
  $sth->execute( 0, $table_name );
  $sth->finish();
}

sub sql_set_all_comma_flags {
  my ( $index, $table_name, $flag_value ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[ UPDATE $table_name SET _comma_flag = ? ]
  );
  $sth->execute( $flag_value );
  $sth->finish();
}

sub sql_clear_all_comma_flags {
  my ( $self, $dbh, $table_name ) = @_;
  my $sth = $dbh->prepare_cached ( 
    qq[ UPDATE $table_name SET _comma_flag = ? ] 
  );
  $sth->execute( 0 );
  $sth->finish();
}

sub sql_clean_find_orphans {
  my ( $index, $table_name, $data_table_name ) = @_;

  return 
  qq[
      SELECT $table_name.doc_id 
      FROM $table_name 
      LEFT JOIN $data_table_name 
        ON $table_name.doc_id = $data_table_name.doc_id 
        WHERE $data_table_name.doc_id is NULL
  ];
}

sub sql_set_comma_flags_for_clean_first_pass {
  my ( $index, $dbh, $data_table_name, $table_name, $erase_where_clause,
       $flag_value ) = @_;

  ## orphan rows in the sort tables. these can be created in small
  ## numbers by the normal fact of entries being cleaned from the data
  ## table before they are removed from the sort tables. orphans can
  ## be created in large numbers by an aborted rebuild() or other
  ## large operation.
  if ( $table_name ne $data_table_name ) {
    my $sql = $index->sql_clean_find_orphans( $table_name, $data_table_name );
    my $sth = $dbh->prepare_cached ( $sql );
    $sth->execute();
    while ( my $row = $sth->fetchrow_arrayref() ) {
      my $orphan_id = $row->[0];
      # print ( "orphan($table_name:$orphan_id)..." );
      my $sth = $dbh->prepare_cached (
        qq[ 
            UPDATE $table_name 
              SET _comma_flag = ?
              WHERE doc_id    = ? 
          ]
      );
      $sth->execute( $flag_value, $orphan_id );
      $sth->finish();
    }
  }

  ## rows matching the erase_where_clause
  if ( $erase_where_clause ) {
    # TODO: come back here and shoehorn $erase_where_clause into using
    # placeholders?
    my $sth = $dbh->prepare_cached (
      qq[
          UPDATE $table_name 
            SET _comma_flag = ?
            WHERE $erase_where_clause
        ]
    );
    $sth->execute( $flag_value );
    $sth->finish();
  }
}

sub sql_set_comma_flags_for_clean_second_pass {
  my ( $self, $dbh, $table_name, $order_by, $sort_spec, $doctype, $indexname,
       $size_limit, $flag_value ) = @_;

  # dbg 'table_name', $table_name;
  # dbg 'order_by', $order_by;
  # dbg 'size_limit', $size_limit;

  # get the index so we can make an iterator
  my $index = XML::Comma::Def->read ( name=>$doctype )->get_index( $indexname );
  # now set the flag for everything after the first size_limit entries
  my $i = $index->iterator ( order_by => $order_by,
                             sort_spec => $sort_spec );
                           
  # dbg 'doc_ids after refresh', $_->doc_id() while ( $_ = $i++ );
  $i->iterator_refresh ( 0xffffff, $size_limit ); # blech, hack

  while ( $i->iterator_next() ) {
    my $id = $i->doc_id();
    my $sth = $dbh->prepare_cached (
      qq[ 
          UPDATE $table_name 
            SET _comma_flag = ?
            WHERE doc_id    = ?
        ]
    );
    $sth->execute( $flag_value, $id );
    $sth->finish();
    # dbg 'set_flag_second', "UPDATE $table_name SET _comma_flag=$flag_value WHERE doc_id='$id'";
  }
}

sub sql_delete_where_not_comma_flags {
  my ( $self, $dbh, $table_name, $flag_value ) = @_;
  my $sth = $dbh->prepare_cached ( 
    qq[
        DELETE FROM $table_name 
          WHERE _comma_flag != ?
      ]
  );
  $sth->execute( $flag_value );
  $sth->finish();
}


sub sql_delete_where_comma_flags {
  my ( $index, $dbh, $table_name, $flag_value ) = @_;
  my $sth = $dbh->prepare_cached ( 
    qq[
        DELETE FROM $table_name 
          WHERE _comma_flag = ?
      ]
  );
  $sth->execute( $flag_value );
  $sth->finish();
}

# XXX not called from anywhere (dug)
sub sql_select_aggregate {
  my ( $index, $aggregate, $field_name, $table_name ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached (
    qq[ SELECT $aggregate($field_name) FROM $table_name ] 
  );
  $sth->execute();
  my $result = $sth->fetchall_arrayref();
  return $result ? $result->[0]->[0] : '';
}

sub sql_select_returns_count {
  return;
}

sub sql_select_distinct_field {
  my ( $it, $index, $field_name, $where ) = @_;
  my $dbh = $index->get_dbh_reader();
  my $data_table_name = $index->data_table_name();
  my $str =  qq[ SELECT DISTINCT $field_name FROM $data_table_name ];
  if ( $where ) {
    $str .= qq[ WHERE $where ];
  }
  my $sth = $dbh->prepare_cached ( $str );
  return $sth;
}

##
# complex select statement build -- for iterator
#
# It would take more tricks than I currently have in my bag to coerce 
# this method into using placeholders (deparsing user specified SQL 
# before re-packing it with placeholders). [dug]
sub sql_select_from_data {
  my ( $iterator, $index, $order_by_expressions, $from_tables,
       $where_clause, $having_clause,
       $distinct, $order_by, $limit_number, $limit_offset,
       $columns_list,
       $collection_spec,
       $textsearch_spec,
       $do_count_only,
       $aggregate_function ) = @_;

  #dbg 'select_from_data', $where_clause;
  my $data_table_name = $index->data_table_name();
  # more hard-coded crappyness.  If we aliased the tables for a 
  # binary collection search we need to make $data_table_name match the 
  # alias.
  foreach my $tbl ( @{ $from_tables } ) {
    if ( $tbl =~ /^\s*$data_table_name AS t01$/ ) {
      $data_table_name = 't01';  last;
    }
  }
  my $dbh = $index->get_dbh_writer();

  my $distinct_string;
  if ( $distinct ) {
    $distinct_string = 'DISTINCT ';
  } else {
    $distinct_string = '';
  }

  # the core part of the statement
  my $select;
  if ( $aggregate_function ) {
    $select = "SELECT $aggregate_function"  if  $aggregate_function;
  } else {
    if ( $do_count_only ) {
      $select = 
        "SELECT COUNT( $distinct_string $data_table_name.doc_id )";
    } else {
      $select = "SELECT $distinct_string";
      $select .= join
        ( ',',
          "$data_table_name.doc_id",

          (map { ref $_
                   ? $_->[0] . '.extra as ' . $_->[1]
                   : "$data_table_name.$_" } @$columns_list),

          "$data_table_name.record_last_modified" );
      
    }
  }

  # extra expressions to select for (the Iterator would have determined
  # that these are used in the order_by)
  my @evalled_order_by_list;
  foreach my $el ( @{$order_by_expressions} ) {
    my $expr = $el->element('expression')->get();
    my $evalled = eval $expr;
    if ( $@ ) {
      die "error while eval'ing order_by '$expr': $@\n";
    }
    push @evalled_order_by_list, [ $el->element('name')->get(), $evalled ];
  }
  my $extra_order_by = join ( ',' , map {
    ' (' . $_->[1] . ') as ' . $_->[0]
  } @evalled_order_by_list );
  $extra_order_by = ',' . $extra_order_by  if  $extra_order_by;

  # from tables
  my $from = ' FROM ' . join ( ',', @{$from_tables} );

  # where clause
  my $where = ' WHERE 1=1';
  $where .= " AND ($where_clause)"     if  $where_clause;
  $where .= " AND $collection_spec"  if  $collection_spec;
  $where .= " AND ($textsearch_spec)"  if  $textsearch_spec;

  # having clause
  my $having = '';
  $having .= " HAVING ($having_clause)" if $having_clause;

  # group by clause
  my $group_by = '';

  # order by clause
  my $order = '';
  if ( $order_by ) {
    $order =  " ORDER BY $order_by";
  }

  # limit what the db server gives back
  my $limit = $index->sql_limit_clause ( $limit_number, $limit_offset );

  # return either a regular statement, a count() statement, or an
  # aggregate statement
  if ( $aggregate_function ) {
    # aggregate ignores limit stuff
    return $select . $from . $where;
  } elsif ( $do_count_only ) {
    # count_only ignores order_by stuff
    return $select . $from . $where . $group_by;
  } else {
    # my ( $package, $filename, $line ) = caller(2);
    #print $select.$extra_order_by.$from.$where.$order.$limit . "\n";
    return $select . $extra_order_by . $from . $where . $having .
      $group_by. $order . $limit;
  }
}
#
##

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

sub sql_create_textsearch_temp_table {
  my ( $index, $ts_index_table_name, $word ) = @_;
  #dbg 'tcreate', $word;
  my $dbh = $index->get_dbh_writer();
  my $packed =
    $index->sql_get_textsearch_index_packed ( $ts_index_table_name, $word ) ||
      return ( '', 0 );

  my ($temp_fh, $temp_filename ) = File::Temp::tempfile
    ( 'comma_db_XXXXXX', DIR => XML::Comma->tmp_directory() );
  my @unpacked = $index->sql_textsearch_unpack_seq_list($packed);
  print $temp_fh join ( "\n", @unpacked ) . "\n";
  close ( $temp_fh );
  chmod 0644, $temp_filename;

  my $temp_table_name = $index->sql_create_textsearch_temp_table_stmt();
  $index->sql_load_data ( $temp_table_name, $temp_filename );

  unlink ( $temp_filename );

  #dbg $$, "created temp table $temp_table_name for $word";
  return ( $temp_table_name, $#unpacked );
}

sub sql_create_textsearch_temp_table_stmt {
  my $index = shift;
  my $dbh   = $index->get_dbh_writer();
  my $temp_table_name = '_temp_' . $$ . '_' . int(rand(0xffffffff));
  my $sth = $dbh->prepare_cached ( 
    qq[
        CREATE TEMPORARY TABLE $temp_table_name 
          ( id VARCHAR(255) PRIMARY KEY ) 
          TYPE=HEAP
    ]);
  $sth->execute();
  $sth->finish();
  return $temp_table_name;
}

sub sql_load_data {
  die "sql_load_data is not implemented";
}

sub sql_drop_any_temp_tables {
  my ( $iterator, $index, $iterator_string, @tables_list ) = @_;
  my $dbh = $index->get_dbh_writer();
  foreach my $t ( grep { /^_temp/ } @tables_list ) {
    # XML::Comma::Log->warn ( "$$ dropping $t for $iterator_string\n" );
    my $sth = $dbh->prepare_cached ( qq[ drop table $t ] );
    $sth->execute();
    $sth->finish();
  }
}

#TODO: replace all these die "foo is not implemented" with more
#      explanatory text (ie foo is a pure virtual function not defined
#      in Base.pm or so...
sub sql_textsearch_cat_seq_list {
  die "sql_textsearch_cat_seq_list is not implemented";
}

1;

