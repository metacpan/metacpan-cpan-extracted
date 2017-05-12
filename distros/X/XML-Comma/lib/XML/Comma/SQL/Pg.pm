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

# PORTING NOTES: started working on making the pg stuff work with
# textsearches, and stopped when it became clear that the "seqs"
# fields need to store arrays of numbers, rather than to be packed, as in mysql.

package XML::Comma::SQL::Pg;
use strict;

use XML::Comma::Util qw( dbg );
use MIME::Base64;

sub sql_create_hold_table {
  my ($self, $dbh) = @_;
  dbg 'creating hold table';
  $dbh->commit();
  my $sth = $dbh->prepare
    ( "CREATE TABLE comma_hold ( key VARCHAR(255) UNIQUE)" );
  $sth->execute();
  $sth->finish();
  $dbh->commit();
}

sub sql_get_hold {
  my ( $lock_singlet, $key ) = @_;
  my $dbh = $lock_singlet->get_dbh();
  my $q_lock_name = $dbh->quote ( $key );
  # dbg 'dbh', $dbh;
  $dbh->{AutoCommit}=0;
  $dbh->commit();
  my $sth = $dbh->prepare
    ( "INSERT INTO comma_hold (key) VALUES ($q_lock_name)" );
  $sth->execute();
  $sth->finish();
}

sub sql_release_hold {
  my ( $lock_singlet, $key ) = @_;
  my $dbh = $lock_singlet->get_dbh();
  my $q_lock_name = $dbh->quote ( $key );
  my $sth = $dbh->prepare ( "DELETE FROM comma_hold WHERE key = $q_lock_name" );
  $sth->execute();
  $sth->finish();
  $dbh->commit();
  $dbh->{AutoCommit}=1;
}

sub sql_create_index_tables_table {
my $index = shift();
my $sth = $index->get_dbh()->prepare (
"CREATE TABLE index_tables
  ( _comma_flag    INT2,
    _sq            SERIAL,
    doctype        VARCHAR(255),
    index_name     VARCHAR(255),
    table_name     VARCHAR(255),
    table_type     INT2,
    last_modified  INT,
    sort_spec      VARCHAR(255),
    textsearch     VARCHAR(255),
    collection     VARCHAR(255),
    index_def      TEXT )"
);
$sth->execute();
$sth->finish();
}


sub sql_sort_table_definition {
  return
"CREATE TABLE $_[1] (
  _comma_flag  INT2,
  doc_id ${ \( $_[0]->element('doc_id_sql_type')->get() ) } PRIMARY KEY )";
}


sub sql_data_table_definition {
  return
"CREATE TABLE $_[1] (
  _comma_flag             INT2,
  record_last_modified    INT4,
  _sq                     SERIAL,
  doc_id ${ \( $_[0]->element('doc_id_sql_type')->get() ) } PRIMARY KEY )";
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
  my ($index, $name) = @_;
  use XML::Comma::Pkg::Textsearch::Preprocessor;
  my $max_length = $XML::Comma::Pkg::Textsearch::Preprocessor::max_word_length;
  return
  qq[
      CREATE TABLE $name (
        word  CHAR($max_length)  PRIMARY KEY,
        seqs  bytea )
  ];
}

sub sql_textsearch_defers_table_definition {
  my ($index, $name) = @_;
  my $doc_id_type = $index->element('doc_id_sql_type')->get();

  return
  qq[
      CREATE TABLE $name (
        doc_id        $doc_id_type,
        action        smallint,
        text          bytea,
        _sq           serial )
  ];
}

sub sql_textsearch_word_lock {
  my ( $index, $i_table_name, $word ) = @_;
  my $dbh = $index->get_dbh_writer();
  $dbh->{AutoCommit}=0;
  $dbh->commit();
  my $sth = $dbh->prepare
    ( "LOCK TABLE $i_table_name IN SHARE ROW EXCLUSIVE MODE" );
  $sth->execute();
  $sth->finish();
}

sub sql_textsearch_word_unlock {
  my ( $index, $i_table_name, $word ) = @_;
  my $dbh = $index->get_dbh_writer();
  #my $q_lock_name = $dbh->quote ( $i_table_name . $word );
  $dbh->commit();
  $dbh->{AutoCommit}=1;
  #$dbh->do ( "COMMIT WORK" );
}


sub sql_index_only_doc_id_type {
  return 'VARCHAR( 255 )';
}


# yech. should we be trying to use the non-standard array *= operators
# in postgres to do this textsearch stuff?
sub sql_textsearch_pack_seq_list {
  shift();
  return '' unless @_;
  return '-' . join ( '-', @_ ) . '-';
}

sub sql_textsearch_unpack_seq_list {
  my @ret = split ( '-', $_[1] );
  shift @ret;
  return @ret;
}

sub sql_textsearch_cat_seq_list {
  my ($self, $packed1, $packed2) = @_;
  chop $packed1;
  return $packed1 . $packed2;
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

# sub sql_load_data {
#   my ( $index, $dbh, $temp_table_name, $temp_filename ) = @_;
#   $dbh->do ( "COPY $temp_table_name FROM '$temp_filename'" );
# }

sub sql_create_textsearch_temp_table_stmt {
  my $index = shift;
  my $dbh   = $index->get_dbh_writer();
  my $temp_table_name = '_temp_' . $$ . '_' . int(rand(0xffffffff));
  my $sth = $dbh->prepare_cached ( 
    qq[
        CREATE TEMPORARY TABLE $temp_table_name 
          ( id VARCHAR(255) PRIMARY KEY ) 
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
        COPY $temp_table_name FROM '$temp_filename'
      ]
  );
  $sth->execute();
  $sth->finish();
}

1;


