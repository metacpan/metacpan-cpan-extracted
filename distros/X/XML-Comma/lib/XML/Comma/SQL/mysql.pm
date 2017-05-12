##
#
#    Copyright 2001-2007, AllAfrica Global Media
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

package XML::Comma::SQL::mysql;

use XML::Comma::Util qw( dbg );
use MIME::Base64;

sub sql_create_hold_table {
# mysql doesn't need a hold table -- uses internal get_lock() and
# release_lock()
}

sub sql_get_hold {
  my ( $lock, $key ) = @_;
  my $dbh = $lock->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( qq[ SELECT GET_LOCK( ? ,86400 ) ] );
  $sth->execute( $key );
  $sth->finish();
}

sub sql_release_hold {
  my ( $lock, $key ) = @_;
  my $dbh = $lock->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( qq[ SELECT RELEASE_LOCK( ? ) ] );
  $sth->execute( $key );
  $sth->finish();
}

sub sql_create_index_tables_table {
  my $index = shift();
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached (
  qq[
      CREATE TABLE index_tables
        ( _comma_flag    TINYINT,
          _sq            INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE,
          doctype        VARCHAR(255),
          index_name     VARCHAR(255),
          table_name     VARCHAR(255),
          table_type     TINYINT,
          last_modified  INT,
          sort_spec      VARCHAR(255),
          textsearch     VARCHAR(255),
          collection     VARCHAR(255),
          index_def      TEXT )
  ]);

  $sth->execute();
  $sth->finish();
}

sub sql_data_table_definition {
  my ($index, $name) = @_;
  my $doc_id_type = $index->element('doc_id_sql_type')->get();

  return
  qq[ 
      CREATE TABLE $name (
        _comma_flag             TINYINT,
        record_last_modified    INT,
        _sq                     INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE,
        doc_id                  $doc_id_type PRIMARY KEY )
  ];
}

sub sql_sort_table_definition {
  my ($index, $name)= @_;
  my $doc_id_type = $index->element('doc_id_sql_type')->get();

  return
  qq[
      CREATE TABLE $name (
         _comma_flag  TINYINT,
         doc_id       $doc_id_type PRIMARY KEY )
  ];
}

sub sql_bcollection_table_definition {
  my ( $index, $name, %arg ) = @_;
  my $extra_column = '';
  if ( @{$arg{bcoll_el}->elements('field')} ) {
    $extra_column = " extra " .
      $arg{bcoll_el}->element('field')->element('sql_type')->get() . ',';
  }

  my $doc_id_type = $index->element('doc_id_sql_type')->get();
  my $bcoll_type  = $arg{bcoll_el}->element('sql_type')->get();

  return
  qq[
      CREATE TABLE $name (
        _comma_flag  TINYINT,
        doc_id $doc_id_type,
        value  $bcoll_type, 
        $extra_column
        INDEX(value),
        UNIQUE INDEX(doc_id,value) )
  ];
}

sub sql_textsearch_index_table_definition {
  my ($index, $name) = @_;
  use XML::Comma::Pkg::Textsearch::Preprocessor;
  my $max_length = $XML::Comma::Pkg::Textsearch::Preprocessor::max_word_length;
  return
  qq[
      CREATE TABLE $name (
        word  CHAR($max_length)  PRIMARY KEY,
        seqs  MEDIUMBLOB )
  ];
}

sub sql_textsearch_defers_table_definition {
  my ($index, $name) = @_;
  my $doc_id_type = $index->element('doc_id_sql_type')->get();

  return
  qq[
      CREATE TABLE $name (
        doc_id        $doc_id_type,
        action        TINYINT,
        text          MEDIUMBLOB,
        _sq           INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE )
  ];
}

sub sql_index_only_doc_id_type {
  return 'VARCHAR( 255 )';
}

sub sql_textsearch_word_lock {
  my ( $index, $i_table_name, $word ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $lock_name = $i_table_name . $word;
  my $sth = $dbh->prepare ( qq[ SELECT GET_LOCK( ? ,1800 ) ] );
  $sth->execute( $lock_name );
  $sth->finish();
}

sub sql_textsearch_word_unlock {
  my ( $index, $i_table_name, $word ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $lock_name = $i_table_name . $word;
  my $sth = $dbh->prepare ( qq[ SELECT RELEASE_LOCK( ? ) ] );
  $sth->execute( $lock_name );
  $sth->finish();
}

sub sql_textsearch_pack_seq_list {
  shift();
  return pack ( "L*", @_ );
}

sub sql_textsearch_unpack_seq_list {
  return unpack ( "L*", $_[1] );
}

sub sql_limit_clause {
  my ( $index, $limit_number, $limit_offset ) = @_;
  if ( $limit_number ) {
    if ( $limit_offset ) {
      return " LIMIT $limit_offset, $limit_number";
    } else {
      return " LIMIT $limit_number";
    }
  } else {
    return '';
  }
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
      ]
  );
  $sth->execute();
  $sth->finish();
  return $temp_table_name;
}

sub sql_load_data {
  my ( $index, $temp_table_name, $temp_filename ) = @_;
  my $dbh = $index->get_dbh_writer();
  my $sth = $dbh->prepare_cached ( 
    qq[
        LOAD DATA LOCAL INFILE "$temp_filename" 
          REPLACE INTO TABLE $temp_table_name
      ] 
  );
  $sth->execute();
  $sth->finish();
}

sub sql_select_returns_count {
  return 1;
}

sub sql_textsearch_cat_seq_list {
  my ($self, $packed1, $packed2) = @_;
  return $packed1 . $packed2;
}

1;
