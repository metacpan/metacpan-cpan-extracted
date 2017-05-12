##
#
#    Copyright 2001-2007 AllAfrica Global Media
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

package XML::Comma::Indexing::Index;

@ISA = qw( XML::Comma::NestedElement
           XML::Comma::Configable
           XML::Comma::Hookable
           XML::Comma::Methodable
           XML::Comma::SQL::DBH_User );

# FIX -- make more of the utility methods here private, and put good
# error-propogation into the utility methods, the sql methods, and
# rebuild() and clean()


use DBI;
use Storable qw( freeze thaw );
use File::Temp qw( tempfile );
use XML::Comma::Util qw( dbg arrayref_remove );
use XML::Comma::Storage::Util;
use XML::Comma::SQL::DBH_User;
use XML::Comma::Indexing::Clean;
use XML::Comma::Indexing::Iterator;
use XML::Comma::Pkg::Textsearch::Preprocessor_En;

use strict;


# _Index_doctype

# _Index_data_table_name  : cached data table name
# _Index_collection_table_names : {} cache of sort_spec name pairs

# _Index_columns     : {} lookup table of fields and collections,
#                         name => { code => code-ref,
#                                   pos  => position,
#                                   type => 'field' | 'collection' }

# _Index_collections : {} lookup table,
#                         name => { el   => sort-element,
#                                   code => code-ref,
#                                   type => name of collection type };
#                                           'stringified' -- the default
#                                           'binary table'
#                                           'many tables'

# _Index_extra_pk_fields : [] primary key fields other than "id"
#                             qw( store doctype )

##
# called on init by the def loader
#
# args -- $parent_doc_type 
#
sub init_and_cast {
  my ( $self, $type ) = @_;
  $self->{_Index_doctype} = $type;
  XML::Comma::SQL::DBH_User::decorate_and_bless ( $self, __PACKAGE__ );
  $self->allow_hook_type ( 'index_hook', 'stop_rebuild_hook' );
  $self->_init_Index_variables();
  $self->_config_dispatcher();
  $self->{DBH_connect_check} = '_check_db';
#  dbg 'index init', $self, $type, $self->def();
  return $self; 
}

sub DATA_TABLE_TYPE              { return 1 };
sub SORT_TABLE_TYPE              { return 2 };
sub TEXTSEARCH_INDEX_TABLE_TYPE  { return 3 };
sub TEXTSEARCH_DEFERS_TABLE_TYPE { return 4 };
sub BCOLLECTION_TABLE_TYPE       { return 5 };

sub _init_Index_variables {
  my $self = shift();
  $self->{_Index_columns_pos} = 1; # (doc_id is always at the zero position)
  my $index_name = $self->element('name')->get();
  # note: initializing these structs is handled here in a sub rather
  # than by config__, so that the sub can be called again to recreate
  # these from element fields, which makes the test add/modify/drop
  # easier.
  #
  # fields
  foreach my $field ( $self->elements('field') ) {
    $self->_init_make_column_entry ( $field, 'field' );
  }
  # stash our valid stores
  if ( $self->element('index_from_store')->get() ) {
    if ( $self->element('store')->get() ) {
      die "index_from_store and store can't co-mingle";
    }
    foreach my $ifs ( $self->elements_group_get('index_from_store') ) {
      if ( index($ifs, ':') > 0 ) {
        $self->{_Index_from_stores}->{ $ifs }++;
      } else {
        $self->{_Index_from_stores}->{ $self->doctype() . ':' . $ifs }++;
      }
    }
    # and make doctype and store available as columns
    foreach my $field ( qw( doctype store ) ) {
      push @{ $self->{ _Index_extra_pk_fields } }, $field;
      $self->_init_make_column_entry ( $field, 'doctype_store' );
    }
  } else { # we can only index from our own doctype to our store name
    $self->{_Index_from_stores}->{ $self->doctype() . ':' . $self->store() }++;
  }
  # collections
  foreach my $collection ( $self->elements('collection'),
                           $self->elements('sort') ) {
    my $name = $collection->element('name')->get();
    my $type = $collection->element('type')->get();
    # dbg 'name/type', $name, $type;
    if ( $self->{_Index_collections}->{$name} ) {
      die "A collection named '$name' (of type '$type') already exists\n";
    }
    if ( $type eq 'stringified' ) {
      $self->_init_make_column_entry ( $collection, 'collection' );
      $self->{_Index_collections}->{$name}->{el} = $collection;
      $self->{_Index_collections}->{$name}->{code} =
        $self->{_Index_columns}->{$name}->{code};
      $self->{_Index_collections}->{$name}->{type} = 'stringified';
    } elsif ( $type eq 'binary table' ) {
      my ($code_element) = $collection->elements('code');
      my $code_ref; 
      if ( $code_element ) {
        $code_ref = eval $code_element->get();
        die "error with code block of collection '$name' " .
          "for index '$index_name': $@\n"  if  $@; 
      } else {
        $code_ref = eval "sub { \$_[0]->auto_dispatch('$name') }";
        die "bad auto-build-code-block error for '$index_name':'$name': $@"
          if $@; 
      }
      $self->{_Index_collections}->{$name}->{el} = $collection;
      $self->{_Index_collections}->{$name}->{code} = $code_ref;
      $self->{_Index_collections}->{$name}->{type} = 'binary table';
    } elsif ( $type eq 'many tables' ) {
      my ($code_element) = $collection->elements('code');
      my $code_ref;
      if ( $code_element ) {
        $code_ref = eval $code_element->get();
        die "error with code block of collection '$name' " .
          "for index '$index_name': $@\n"  if  $@;
      } else {
        $code_ref = eval "sub { \$_[0]->auto_dispatch('$name') }";
        die "bad auto-build-code-block error for '$index_name':'$name': $@"
          if $@;
      }
      $self->{_Index_collections}->{$name}->{el} = $collection;
      $self->{_Index_collections}->{$name}->{code} = $code_ref;
      $self->{_Index_collections}->{$name}->{type} = 'many tables';
    } else {
      die "no such type '$type' recognized for collection '$name'\n"; 
    }
  }
}

sub _init_check_for_double_defines {
  my ( $self, $index_name, $el ) = @_;
  my $name = $el->element('name')->get();
  if ( $self->{_Index_columns}->{$name} ) {
    die "multiple columns named '$name' for index '$index_name'\n"; 
  }
  return $name; 
}

sub _init_make_column_entry {
  my ( $self, $el, $type ) = @_;
  my $index_name = $self->element('name')->get();
  #dbg "making_column:", $index_name, $el->name(), $type;
  my $code_ref; 
  my ( $name, $code_element );
  if ( $type eq 'doctype_store' ) {
    $name = $el;
  } else {
    $name = $self->_init_check_for_double_defines ( $index_name, $el );
    ($code_element) = $el->elements('code');
  }
  if ( $code_element ) {
    $code_ref = eval $code_element->get();
    die "error with code block of $type '$name' " .
        "for index '$index_name': $@\n" if $@; 
  } else {
   if ( $el eq 'store' ) { 
      $code_ref = eval "sub { \$_[0]->doc_store()->name() }";
      die "error with code block of $type '$name' " .
          "for index '$index_name': $@\n" if $@; 
    } elsif ( $el eq 'doctype' ) {
      $code_ref = eval "sub { \$_[0]->doc_store()->doctype() }";
      die "error with code block of $type '$name' " .
          "for index '$index_name': $@\n" if $@; 
    } else {
      $code_ref = eval "sub { \$_[0]->auto_dispatch('$name') }";
      die "error with code block of $type '$name' " .
          "for index '$index_name': $@\n" if $@; 
    }
  }
  die "could not get a code reference of $type '$name' in index '$index_name'\n"
    unless $code_ref;
  $self->{_Index_columns}->{$name}->{code} = $code_ref;
  $self->{_Index_columns}->{$name}->{pos} = $self->{_Index_columns_pos}++;
  $self->{_Index_columns}->{$name}->{type} = $type; 
}

sub _config__index_hook {
  my ( $self, $el ) = @_;
  #dbg 'ih', $self->name(), $el->to_string();
  $self->add_hook ( 'index_hook', $el->get() );
}

sub _config__stop_rebuild_hook {
  my ( $self, $el ) = @_;
  $self->add_hook ( 'stop_rebuild_hook', $el->get() );
}

sub columns {
  return
    sort { $_[0]->{_Index_columns}->{$a}->{pos} <=>
             $_[0]->{_Index_columns}->{$b}->{pos}
           } keys %{$_[0]->{_Index_columns}};
}

sub column_type {
  return '' if $_[1] eq 'doc_id' or $_[1] eq 'record_last_modified';
  return $_[0]->{_Index_columns}->{$_[1]}->{type} || do {
    delete ${$_[0]->{_Index_columns}}{$_[1]};
    return '';
  }
}

sub column_value {
  my ( $index, $column_name, $doc ) = @_;
  my $column = $index->{_Index_columns}->{$column_name} ||
    die "no such column as '$_[0]' found for index '$column_name'\n";
  if ( $column->{type} eq 'field'  or  $column->{type} eq 'doctype_store' ) {
    return  scalar  $column->{code}->($doc,$index);
  } elsif ( $column->{type} eq 'collection' ) {
    return
      $index->collection_stringify_concat( $column->{code}->($doc,$index) );
  } else {
    die "unrecoginized column type\n";
  }
}

sub field_names {
  return map { $_->element('name')->get(); } $_[0]->elements('field');
}

# DEPRECATED
sub sort_names {
  return $_[0]->collection_names();
};

sub collection_names {
  return keys %{$_[0]->{_Index_collections}};
};

sub collection_type {
  my $cref = $_[0]->{_Index_collections}->{$_[1]};
  return unless $cref;
  return $cref->{type};
}

sub collection_field {
  my $cref = $_[0]->{_Index_collections}->{$_[1]};
  return unless $cref;
  my ( $field ) = $cref->{el}->elements('field');
  #dbg 'cref', $field, $field->to_string, $cref->{el}->to_string;
  return $field if $field;
  return;
}

sub textsearch_names {
  return map { $_->element('name')->get(); } $_[0]->elements('textsearch');
};

####
## routines for dealing with "stringify" type collections
use Data::Dumper;
BEGIN {
  $Data::Dumper::Terse = 1;
  $Data::Dumper::Indent = 0;
}
sub collection_stringify_concat {
  shift();
  return Data::Dumper->Dump( [ \@_] );
}

sub collection_stringify_partial {
  shift();
  return Data::Dumper->Dump( \@_ );
}

sub collection_stringify_unconcat {
  my ( $self, $string ) = @_; 
  my $list = eval $string; 
  die "error retrieving from collection: $@\n"  if  $@; 
  return $list; 
}
##
####


# used to get a sort element, or as a boolean to tell if one is legal
# (ie, defined).
sub get_collection {
  my $entry = $_[0]->{_Index_collections}->{$_[1]};
  return  defined $entry  ?  $entry->{el}  :  undef;
}


sub update {
  my ( $self, $doc, $comma_flag, $defer_textsearches ) = @_;

  # ensure this document is allowed to update the index it's trying to
  $self->_can_alter_index_p( $doc ) or 
    XML::Comma::Log->err( 
      'INDEX_UPDATE_ERROR', $doc->doc_key() . 
      " can't update index '" . $self->doctype() . ':' . $self->name() . "'"
    );

### note: why was this added and then commented out? do we want it?
#    # user must have -w access to $doc to be allowed to update the index
#    if ( ! -w $doc->storage_filename() ) {
#      XML::Comma::Log->err ( 'INDEX_PERMISSION_DENIED',
#                             'update on ' . $self->name() . ' failed' );
#    }
  # run index hooks, passing doc and self as args. if any of the index
  # hooks die, then we simply don't index this doc.
  my ($skip_update, @update_errors); 
  foreach my $sub ( @{$self->get_hooks_arrayref('index_hook')} ) {
    eval {
      $sub->( $doc, $self );
    }; if ( my $err = $@ ) {
      #die() doesn't percolate, but die("foo") does percolate
      #to a warn() call. both mean we remove the index, b/c
      #either an error or user-initiated skip occurred
      $skip_update = 1;
      push @update_errors, $err if($err !~ /^Died at/); 
    }
  }

  if($skip_update) {
    # (okay, check to see if this doc was already in the index, and if
    # so, remove it.
    if ( $self->sql_key_indexed_p( $doc->doc_key(), $doc->doc_id()) ) {
      $doc->index_remove ( index => $self->name() );
    }
    # in comma > 1.995, we assume that this is an unexpected SQL or
    # user code error - previously this error was swallowed. To stop
    # an indexing from happening, use die with no argument or you 
    # will continue to receive such warnings. TODO: note this in guide
    my $msg = "WARNING: an index_hook for doc '".$doc->doc_key."' on index '".$self->name(). "' died with true value: "; 
    foreach my $err (@update_errors) {
      XML::Comma::Log->warn($msg.$err) if($err); 
    }
    return;
  }

  if ( ! $self->sql_key_indexed_p( $doc->doc_key(), $doc->doc_id()) ) {
    # this is a new insert
    $self->sql_insert_into_data ( $doc, $comma_flag );
    $self->sql_update_timestamp ( $self->data_table_name() );

    while ( my ($cname,$cref) = each %{$self->{_Index_collections}} ) {
      $self->_do_collection ( $doc, $cname, $cref );
    }

    foreach my $textsearch ( $self->elements('textsearch') ) {
      if ( $defer_textsearches or
           $textsearch->element('defer_on_update')->get() ) {
        $self->_defer_do_textsearch ( $doc, $textsearch );
      } else {
        $self->_do_textsearch ( $doc, $textsearch );
      }
    }

  } else {
    # this is an update of an existing record
    $self->sql_update_in_data ( $doc, $comma_flag );
    $self->sql_update_timestamp ( $self->data_table_name() );

    while ( my ($cname,$cref) = each %{$self->{_Index_collections}} ) {
      $self->_undo_collection ( $doc, $cname, $cref);
      $self->_do_collection ( $doc, $cname, $cref );
    }

    foreach my $textsearch ( $self->elements('textsearch') ) {
      if ( $defer_textsearches or
           $textsearch->element('defer_on_update')->get() ) {
        $self->_defer_undo_textsearch ( $doc, $textsearch );
        $self->_defer_do_textsearch ( $doc, $textsearch );
      } else {
        $self->_undo_textsearch ( $doc, $textsearch );
        $self->_do_textsearch ( $doc, $textsearch );
      }
    }

  }
  $self->_maybe_clean();
  return 1;
}


sub delete {
  my ( $self, $doc ) = @_;
#    # user must have -w access to $doc to be allowed to update the index
#    if ( ! -w $doc->storage_filename() ) {
#      XML::Comma::Log->err ( 'INDEX_PERMISSION_DENIED',
#                             'delete on ' . $self->name() . ' failed' );
#    }
  # need to delete from textsearch before deleting from data
  foreach my $textsearch ( $self->elements('textsearch') ) {
    $self->_undo_textsearch ( $doc, $textsearch );
  }
  # data tables
  $self->sql_delete_from_data ( $doc );
  $self->sql_update_timestamp ( $self->data_table_name() );

  while ( my ($cname,$cref) = each %{$self->{_Index_collections}} ) {
    $self->_undo_collection ( $doc, $cname, $cref);
  }

  foreach my $textsearch ( $self->elements('textsearch') ) {
    $self->_undo_textsearch ( $doc, $textsearch );
  }
  1;
}

sub _can_alter_index_p {
  my ( $self, $doc ) = @_;
  
  # index_only is special
  $doc->doc_id() eq 'COMMA_DB_SEQUENCE_SET' and return 1;
  
  my ( $doctype, $store, $id ) = 
    XML::Comma::Storage::Util->split_key( $doc->doc_key() );
  
  return $self->{_Index_from_stores}->{ "$doctype:$store" };
}

sub iterator {
  my ( $self, %args ) = @_;
  my $iterator = eval { XML::Comma::Indexing::Iterator->new ( index => $self,
                                                              %args ); };
  if ( $@ ) { XML::Comma::Log->err ( 'INDEX_ERROR', $@ ); }
  return $iterator; 
}

sub single_retrieve {
  my ( $self, %args ) = @_; 
  my $ret = eval {
    my $iterator = XML::Comma::Indexing::Iterator->new ( index => $self,
                                                         %args );
    if ( $iterator->iterator_refresh(1)->iterator_has_stuff() ) {
      return $iterator->retrieve_doc();
    } else {
      return;
    }
  }; if ( $@ ) { XML::Comma::Log->err ( 'INDEX_ERROR', $@ ); }
  return $ret; 
}

sub single_read {
  my ( $self, %args ) = @_; 
  my $ret = eval {
    my $iterator = XML::Comma::Indexing::Iterator->new ( index => $self,
                                                         %args );
    if ( $iterator->iterator_refresh(1)->iterator_has_stuff() ) {
      return $iterator->read_doc();
    } else {
      return;
    }
  }; if ( $@ ) { XML::Comma::Log->err ( 'INDEX_ERROR', $@ ); }
  return $ret; 
}

sub single {
  my ( $self, %args ) = @_; 
  my $ret = eval {
    my $iterator = XML::Comma::Indexing::Iterator->new ( index => $self,
                                                         %args );
    if ( $iterator->iterator_refresh(1)->iterator_has_stuff() ) {
      return $iterator; 
    } else {
      return;
    }
  }; if ( $@ ) { XML::Comma::Log->err ( 'INDEX_ERROR', $@ ); }
  return $ret; 
}

sub count {
  my ( $self, %args ) = @_; 
  my $count = eval { XML::Comma::Indexing::Iterator->count_only ( index=>$self,
                                                                  %args ); };
  if ( $@ ) { XML::Comma::Log->err ( 'INDEX_ERROR', $@ ); }
  return $count; 
}

sub aggregate {
  my ( $self, %args ) = @_;
  my $count = eval { XML::Comma::Indexing::Iterator->aggregate ( index=>$self,
                                                                 %args ); };
  if ( $@ ) { XML::Comma::Log->err ( 'INDEX_ERROR', $@ ); }
  return $count; 
}

sub distinct_field_values {
  my ( $self, $field_name, %args ) = @_; 
  my @list = eval {
    XML::Comma::Indexing::Iterator->distinct_field_values
        ( index => $self, _field_name => $field_name, %args ); 
  };
  if ( $@ ) { XML::Comma::Log->err ( 'INDEX_ERROR', $@ ); }
  return @list; 
}


# calls sql_drop_table to drop the table and remove the index_tables entry
sub drop_table {
  my ( $self, $table_name ) = @_;
  $self->sql_drop_table ( $table_name );
}


sub doctype {
  return $_[0]->{_Index_doctype};
}

sub store {
  return $_[0]->{_Index_store_type} ||=
    $_[0]->element('store')->get() || $_[0]->element('name')->get();
}

sub fully_qualified_name {
  my $self = shift();
  return $self->{_Index_doctype} . '_' . $self->element('name')->get();
}

sub data_table_name {
  return $_[0]->{_Index_data_table_name} ||= $_[0]->sql_data_table_name()
    || die "no data table name\n";
}

# takes either a single-argument sort-spec, or two arguments:
# sort_name and sort_string. returns the data_table name for
# 'stringified' collections, the bcollection_table_name for 'binary
# table' collections, and the sort_table name for 'many tables'
# collections. if a sort_name/spec pair is given and no table exists,
# returns the empty string.
sub collection_table_name {
  my $self = shift();
  my $sort_spec; my $sort_name; my $sort_val; 
  if ( scalar(@_) > 1 ) {
    $sort_name = $_[0];
    $sort_val = $_[1];
    $sort_spec = $self->make_sort_spec($sort_name, $sort_val); 
  } else {
    $sort_spec = shift();
    ( $sort_name, $sort_val ) = $self->split_sort_spec($sort_spec); 
  }

  my $table_name = $self->{_Index_collection_table_names}->{$sort_spec};
  # return cached value if we have it
  return $table_name if $table_name;

  # otherwise we need to get, cache and return, with what we do to
  # "get" different depending on the collection type
  my $cref = $self->{_Index_collections}->{$sort_name}; 
  die "bad collection name '$sort_name'\n"  unless  defined $cref;
  $table_name = $self->data_table_name()
    if  $cref->{type} eq 'stringified';
  $table_name = $self->sql_get_bcollection_table ( $sort_name )
    if  $cref->{type} eq 'binary table';
  $table_name = $self->sql_get_sort_table_for_spec ( $sort_spec )
    if $cref->{type} eq 'many tables';
  return $self->{_Index_collection_table_names}->{$sort_spec} ||= $table_name; 
}


sub last_modified_time {
  my ( $self, $sort_name, $sort_string ) = @_; 
  my $ret = eval {
    my $table_name;
    if ( $sort_name ) {
      $table_name = $self->collection_table_name ( $sort_name, $sort_string );
    } else {
      $table_name = $self->data_table_name();
    }
    return $self->sql_get_timestamp ( $table_name );
  }; if ( $@ ) { XML::Comma::Log->err ( 'INDEX_ERROR', $@ ); }
  return $ret; 
}

#TODO: this is VERY dangerous, it breaks caching, which means you
#can't rebuild after until you've started a different process or so
sub erase {
  my ($self, %args) = @_; 
  die "this method is very dangerous, if you really want to do it, read the source for caveats" unless($args{really}); 
  my $dbh  = $self->get_dbh;
  my $name = $self->{_Index_doctype};
  #first, delete the index_tables, then delete the actual tables
  #this should keep confusion to a minimum...
  my $sth  = $dbh->prepare( qq {
    select table_name from index_tables where doctype = '$name'; 
  } );
  $sth->execute(); 
  my @dead_tables;
  while ( my @row = $sth->fetchrow_array ) { push @dead_tables, @row };
  $dbh->do( qq {
    delete from index_tables where doctype = '$name';
  } );
  $dbh->do("drop table $_;") foreach (@dead_tables); 
}

## set the flag of every document that is in a table just before the
## rebuild starts on that table. do the rebuild -- unsetting the flag
## when a record is "touched". then erase every item with the flag
## set.
#
# args: verbose=>[0|1], #default 0
#       size=>n,
#       workers =>n,
#       stores=>[doctype:store, ...]
#       defer_textsearches => [0|1] #default 1 on mysql, 0 on pg
sub rebuild {
  my ( $self, %args ) = @_;
  my @stores = $self->_get_stores_for_rebuild ( %args );
  local $SIG{INT} = sub {
    print "Received interrupt signal during rebuild: cleaning up...\n";
    $self->sql_unset_all_table_comma_flags();
    print "Okay, exiting. note that the rebuild did not complete\n";
    print "  due to the Ctrl-C. you may want to run rebuild() again.\n";
    exit ( 0 );
  };
  my $rebuild_flag = int( rand(127) );
  # we need to wait for all flags to be clear before we can proceed
  $self->sql_set_all_table_comma_flags_politely ( $rebuild_flag );
  while ( my @in_use =
          $self->sql_get_all_tables_with_comma_flags_set($rebuild_flag) ) {
    print "waiting for tables: (flag $rebuild_flag) " .
      join ( ',', @in_use ) . "\n";
    $self->sql_set_all_table_comma_flags_politely ( $rebuild_flag );
    sleep 5;
  }
  # set all the _comma_flags in the data table to our rebuild value
  $self->sql_set_all_comma_flags ( $self->data_table_name(), $rebuild_flag );
  # do the looping, inside an eval so we can unset the flag on any error
  foreach my $store ( @stores ) {
    if ( $args{verbose} ) {
      print "beginning re-index from store " . $store->name() . "...\n";
    }
    eval { $self->_rebuild_loop ( $rebuild_flag, $store, %args ); };
     if ( $@ ) {
      my $error = $@;
      eval { $self->sql_unset_all_table_comma_flags(); };
      die "error while rebuilding: $error\n";
    }
    if ( $args{verbose} ) {
      print "finished re-index from store " . $store->name() . "...\n";
    }
  }
  if ( $args{verbose} ) {
    print "done re-indexing...\n";
    print "deleting entries not added by rebuild...\n";
  }
  $self->sql_delete_where_comma_flags ( $self->get_dbh_writer(),
                                 $self->data_table_name(),
                                 $rebuild_flag );
  $self->sql_clear_all_comma_flags ( $self->get_dbh_writer(), $self->data_table_name() );
  $self->sql_unset_all_table_comma_flags();
  print "cleaning...\n"  if  $args{verbose};
  # complete clean will get rid of entries in sort tables that are not
  # in data table
  $self->clean();
}

sub _rebuild_loop {
  my ( $self, $rebuild_flag, $store, %args ) = @_;
  #unspecified defer_textsearches defaults to 1 unless we are using
  #postgres, which has problems with deferred textsearches at the moment
  my $defer_textsearches = defined($args{defer_textsearches}) ?
    $args{defer_textsearches} :
    (XML::Comma->system_db() ne 'postgres');
  #if we're running postgres and we got an explicit defer_textsearches,
  #die with some explanatory text abot the sitation
  if($args{defer_textsearches} && (XML::Comma->system_db() eq 'postgres')) {
    #TODO: index_update() probably have this warning too...
    die "defer_textsearches is BROKEN with postgres at the moment, please remove the defer_textsearches argument to your rebuild() call";
  }
  # don't do anything if there's nothing stored (avoids "can't stat" warning)
  return  if  ! -d $store->base_directory();
  # get iterator
  my $iterator = $store->iterator( size => $args{size} || 0xffffffff );
  # do some forking, if necessary
  my ( $im_a_child, $offset ) = $self->_rebuild_fork ( $iterator,
                                                       $args{workers} ||= 1 );
  # setup and loop
  my $doc = $iterator->prev_read();
  my $count = $offset + 1;

  my $index_doctype = $self->doctype(); # the def's doctypetype
  my $index_name    = $self->element('name')->get();

  my $stopped;
  while ( $doc && ! $stopped  ) {
    eval {
      if ( $args{verbose} ) {
        print "updating " . $doc->doc_id() . " (" . $count . ")\n";
      }
      $doc->index_update ( index      => "$index_doctype:$index_name",
                           comma_flag => 0,
                           defer_textsearches => $defer_textsearches );
      # run stop_rebuild_hooks, passing $doc and $self. if any of the subs
      # return true, then we should exit from the rebuild
      foreach my $sub ( @{$self->get_hooks_arrayref('stop_rebuild_hook')} ) {
        if ( $sub->( $doc, $self ) ) {
          $stopped++;
          return; # break out of eval
        }
      }
      # set in-use flags again, in case we've created sort tables
      $self->sql_set_all_table_comma_flags_politely ( $rebuild_flag );
      # periodically write out textsearches cache, to avoid a big
      # memory/db-size bottleneck
      unless ( $count % 2000 ) {
        print "pausing to do deferred textsearches...\n"  if  $args{verbose};
        $self->sync_deferred_textsearches()
      }
      $iterator->inc ( -1 * ($args{workers}-1) )  if  $args{workers}>1;
      $doc = $iterator->prev_read();
    }; if ( $@ ) {
      my $err = $@;
      my $err_str = "error while in rebuild loop (" .
                              $iterator->doc_id() . "): $err";
      print STDERR $err_str;
      XML::Comma::Log->warn ( $err_str );
      # try again to read, even after error, so we can keep
      # looping.
    RESET_FOR_LOOP: eval {
        $iterator->inc ( -1 * ($args{workers}-1) )  if  $args{workers}>1;
        $doc = $iterator->prev_read();
      }; if ( $@ ) {
        XML::Comma::Log->warn ( "error while in rebuild loop " .
                                $doc->doc_key() . ": $@" );
        goto "RESET_FOR_LOOP";
      };
    }
    $count += $args{workers};
  }


  #dbg "done updating\n";
  # say goodbye if I'm a child, my work is done
  exit ( 0 )  if  $im_a_child;
  # wait on all my beloved children
  while ( wait() > -1 ) { ;; }
  # and do whatever textsearches we had postponed
  print "finishing deferred textsearches...\n"  if  $args{verbose};
  $self->sync_deferred_textsearches();
}

sub _rebuild_fork {
  my ( $self, $iterator, $workers ) = @_;
  my $im_a_child = 0;
  my $offset = 0;
  foreach ( 1 .. ($workers - 1) ) {
    #dbg 'forking';
    unless ( my $pid = fork() ) {
      $self->get_dbh_writer();
      $im_a_child = 1;
      $offset = $_;
      $SIG{INT} = 'DEFAULT';
      last;
    }
  }
  foreach ( 1..$offset ) { $iterator->inc(-1); }
  return ( $im_a_child, $offset );
}

# Ensure that the rebuild process has valid stores to rebuild, either
# as specified by a stores => [] argument or as implied by the index
# declaration in the def
sub _get_stores_for_rebuild {
  my ( $self, %args ) = @_;

  my %stores;

  if ( $args{ stores } ) { 
    foreach my $store_arg ( @{ $args{ stores } } ) {
      my ( $doctype, $store );
      if ( index($store_arg, ':') > 0 ) {
        ( $doctype, $store ) = split /:/, $store_arg;
      } else { 
        $doctype = $self->doctype();
        $store   = $store_arg;
        $store_arg = $doctype . ':' . $store;
      }
      unless ( $self->{_Index_from_stores}->{ $store_arg } ) {
        XML::Comma::Log->err( 'INDEX_REBUILD_ERROR', "Index '" .
                              $self->element('name')->get . "'" . 
                              " can't rebuild from '$store_arg'" );
      }
      eval {
        $stores{ $store_arg } = XML::Comma::Def->read( name => $doctype )
                                                     ->get_store( $store );
      }; if ( $@ ) {
        XML::Comma::Log->err( 'INDEX_REBUILD_ERROR', $@ );
      }
    }
  } else {
    foreach my $store_arg ( keys %{ $self->{_Index_from_stores} } ) {
      my ( $doctype, $store ) = split /:/, $store_arg;
        $stores{ $store_arg } =  XML::Comma::Def->read( name => $doctype )
                                                ->get_store( $store );
    }
  }
  return values %stores;
}

# if called with no arguments, cleans the data table, and everything
# else, too. otherwise, call with sort_table_name
# indicating which sort table to clean
sub clean {
  my ( $self, $table_name ) = @_;
  my $clean_element;

  if ( $table_name ) {
    my $sort_spec = $self->sql_get_sort_spec_for_table ( $table_name );
    my ( $sort_name, $sort_string ) = $self->split_sort_spec ( $sort_spec );
    # quote the sort_spec because it might have spaces (yech, blech)
    $sort_spec = "'$sort_spec'";
    # needs to have a clean defined, with a 'to_size'
    my $sort = $self->get_collection ( $sort_name );
    #dbg 'doing clean for' , $table_name, $sort_name, $sort_string;
    ( $clean_element ) = $sort->elements ( 'clean' );
    if ( ! $clean_element ) { return; }
    warn "clean for '$sort_name' doesn't have a to_size\n"
      if  ! $clean_element->to_size();
    XML::Comma::Indexing::Clean->
        init_and_cast ( element => $clean_element,
                        doctype => $self->{_Index_doctype},
                        index_name => $self->name(),
                        dbh => $self->get_dbh_writer(),
                        order_by =>
                          $clean_element->element('order_by')->get() ||
                            $self->element('default_order_by')->get(),
                        sort_spec => $sort_spec,
                        table_name => $table_name,
                        data_table_name => $self->data_table_name() )->clean();
  } else {
    # clean everything
    eval {
      $table_name = $self->data_table_name();
      ( $clean_element ) = $self->elements ( 'clean' );
      if ( ! $clean_element ) { return; }
      # commented out the following warning, as it seems reasonable to
      # define a clean that only has an erase_where_clause warn
      #       "overall clean doesn't have a to_size\n" if !
      #         $clean_element->to_size(); clean data table
      my @bctns = $self->sql_get_bcollection_table();
      XML::Comma::Indexing::Clean->
          init_and_cast ( element => $clean_element,
                          doctype => $self->{_Index_doctype},
                          index_name => $self->name(),
                          dbh => $self->get_dbh_writer(),
                          order_by =>
                            $clean_element->element('order_by')->get() ||
                              $self->element('default_order_by')->get(),
                          table_name => $table_name,
                          data_table_name => $table_name,
                          bcollection_table_names => \@bctns )->clean();
      # now loop through and call ourself again to clean everything else
      foreach my $table ( $self->sql_get_sort_tables() ) {
        $self->clean ( $table );
      }
    }; if ( $@ ) {
      my $error = $@;
      eval { $self->sql_clear_all_comma_flags ( $self->get_dbh_writer(), 'index_tables' ); };
      die "error while doing a complete clean: $error\n";
    }
  }
}

# takes two arguments, a sort_name and a sort_string
sub make_sort_spec {
  my ( $self, $name, $string ) = @_;
  my $spec = "$_[1]:$_[2]";
  $spec =~ s/(?<!\\)'/\\'/g; # 'escape' single quotes
  return $spec;
}

# takes a sort_spec as an argument and returns ( name, string )
sub split_sort_spec {
  my ( $name, $string ) = split ( ':', $_[1], 2 );
  return ( $name, $string );
}

sub def_name {
  return $_[0]->{_Index_doctype};
}

sub table_exists {
  my ( $self, $table_name ) = @_;
  return $self->sql_get_timestamp ( $table_name );
}

##
#
sub _do_collection {
  my ( $self, $doc, $cname, $cref ) = @_;
  # don't do anything for 'stringified' collections; they're handled
  # by the data_table routines
  return  if  $cref->{type} eq 'stringified';
  # binary table
  if ( $cref->{type} eq 'binary table' ) {
    my %seen = ();
    my $table_name =
      $self->sql_get_bcollection_table ( $cname ) ||
        die "bad collection table fetch for $cname\n";

    my $extra_name;
    if ( my ( $field ) = @{$cref->{el}->elements('field')} ) {
      $extra_name = $field->name;
    }

    foreach my $col ( $cref->{code}->($doc) ) {
      my $col_str;
      my $extra = '';
      if ( ref $col ) {
        $col_str = $col->{_};
        $extra   = $col->{$extra_name};
      } else {
        $col_str = $col;
      }
      # dbg 'col:', $col, $col_str, $extra;
      unless ( $seen{$col_str}++ ) {
        eval {
          $self->sql_insert_into_bcollection
            ( $table_name, $doc->doc_id(), $col_str, $extra );
        }; if ( $@ ) {
          # ignore unless debugging?
          XML::Comma::Log->warn ( "collection (binary) error: $@" );
        }
      }
    }
  }
  # many tables
  elsif ( $cref->{type} eq 'many tables' ) {
    my %seen = ();
    foreach my $col_string ( $cref->{code}->($doc) ) {
      unless ( $seen{$col_string}++ ) {
        my $table_name = $self->_maybe_create_sort_table ($cname, $col_string);
        # it is possible for there to have been a bug somewhere else (a
        # failure in _undo_sort, for example, that will cause this insert
        # to die.) wille can catch and ignore errors, here, on the theory
        # that a slightly-wrong sort table isn't the end of the world.
        eval {
          $self->sql_insert_into_sort ( $doc->doc_id(), $table_name );
          $self->_maybe_clean ( $table_name, $cname );
          $self->sql_update_timestamp ( $table_name );
        }; if ( $@ ) {
          # ignore unless debugging?
          XML::Comma::Log->warn ( "collection (sort) error: $@" );
        }
      }
    }
  }
  # we shouldn't ever get here
  else {
    die "unrecoverable error, bad collection type '" . $cref->{type} . "'\n";
  }
}

sub _undo_collection {
  my ( $self, $doc, $cname, $cref ) = @_;
  return  if  $cref->{type} eq 'stringified';
  # binary table
  if ( $cref->{type} eq 'binary table' ) {
    my $table_name = $self->sql_get_bcollection_table ( $cname ) ||
      die "bad collection table fetch for '$cname'\n";
    $self->sql_delete_from_bcollection ( $doc->doc_id(), $table_name );
  }
  # many tables
  elsif ( $cref->{type} eq 'many tables' ) {
    foreach my $table_name ( $self->sql_get_sort_tables( $cname ) ) {
      my $rows = $self->sql_delete_from_sort ( $doc->doc_id(), $table_name );
      $self->sql_update_timestamp ( $table_name )  if  $rows > 0;
    }
  }
  # we shouldn't ever get here
  else {
    die "unrecoverable error, bad collection type '" . $cref->{type} . "'\n";
  }
}

##
# A note on sort table last_modified timestamps: any time a document
# that appears in any sort table is update()ed or delete()ed, the
# last_modified timestamp changes. It doesn't matter if the document
# was already in the sort. this is probably the right thing, so that
# iterators that depend on columns from the data table will be sure to
# be able to refresh as needed.\
##

sub _maybe_create_sort_table {
  my ( $self, $sort_name, $sort_string ) = @_;
  my $table_name = $self->collection_table_name ( $sort_name, $sort_string );
  unless ( $table_name ) {
    # get CREATE_TABLE_HOLD
    XML::Comma::lock_singlet()->wait_for_hold ( "CREATE_TABLE_HOLD" );
    # check again for table name after we've gotten the hold
    $table_name = $self->collection_table_name ( $sort_name, $sort_string );
    unless ( $table_name ) {
      my $sort_spec = $self->make_sort_spec( $sort_name, $sort_string );
      $table_name = $self->sql_create_sort_table ( $sort_spec );
      $self->{_Index_collection_table_names}->{$sort_name} = $table_name;
    }
    # release the hold
    XML::Comma::lock_singlet()->release_hold ( "CREATE_TABLE_HOLD" );
  }
  return $table_name;
}

#  sub _do_bcollection {
#    my ( $self, $doc, $bcollection_name ) = @_;
#    my $qdoc_id = $self->get_dbh()->quote ( $doc->doc_id() );
#    my $table_name = sql_get_bcollection_table_name($self, $bcollection_name) ||
#      die "bad collection table fetch for $bcollection_name\n";
#    foreach my $col_str
#      ( $self->{_Index_bcollections}->{$bcollection_name}->{code}->($doc) ) {
#        eval {
#          sql_insert_into_bcollection ( $self, $table_name, $qdoc_id, $col_str );
#        }; if ( $@ ) {
#          warn "_do_bcollection_error: $@";
#        }
#      }
#  }

#  sub _undo_bcollection {
#    my ( $self, $doc, $bcollection_name ) = @_;
#    my $qdoc_id = $self->get_dbh()->quote ( $doc->doc_id() );
#    my $table_name = sql_get_bcollection_table_name($self, $bcollection_name) ||
#      die "bad collection table fetch for $bcollection_name\n";
#    sql_delete_from_bcollection ( $self, $table_name, $qdoc_id );
#  }

sub _do_textsearch {
  my ( $self, $doc, $textsearch ) = @_;
  my $name = $textsearch->element('name')->get();
  my ( $i_table_name ) = $self->sql_get_textsearch_tables ( $name );
  die "fatal error: no textsearch_index table found for '$name'\n"
    if ! $i_table_name;
  # inverted index records
  foreach my $word ( $self->_get_textsearch_words($doc, $textsearch) ) {
    $self->sql_update_in_textsearch_index_table
      ( $i_table_name,
        $word,
        $doc->doc_id() );
  }
}

sub _defer_do_textsearch {
  my ( $self, $doc, $textsearch ) = @_;
  my ( $i_table_name, $d_table_name ) = $self->sql_get_textsearch_tables
    ( $textsearch->element('name')->get() );
  my @words = $self->_get_textsearch_words($doc, $textsearch);
  $self->sql_textsearch_defer_update 
    ( $d_table_name, $doc->doc_id(), freeze(\@words) );
}

sub _undo_textsearch {
  my ( $self, $doc, $textsearch ) = @_;
  my $name = $textsearch->element('name')->get();
  my ( $i_table_name ) = $self->sql_get_textsearch_tables ( $name );
  die "fatal error: no textsearch_index table found for '$name'\n"
    if ! $i_table_name;
  # inverted index records
  $self->sql_delete_from_textsearch_index_table ( 
                                           $i_table_name,
                                           $doc->doc_id() );
}

sub _defer_undo_textsearch {
  my ( $self, $doc, $textsearch ) = @_;
  my ( $i_table_name, $d_table_name ) = $self->sql_get_textsearch_tables 
    ( $textsearch->element('name')->get() );
  $self->sql_textsearch_defer_delete ( $d_table_name, $doc->doc_id() );
}

sub _get_textsearch_words {
  my ( $self, $doc, $textsearch ) = @_;
  # compile the 'which_preprocessor' sub and cache it, if
  # necessary. the default here is filled from the Bootstrap def.
  $textsearch->{_comma_compiled_which_preprocessor} ||=
    eval $textsearch->element('which_preprocessor')->get();
  if ( $@ ) {
    die "textsearch '" . $textsearch->element('name')->get() .
      "' died during eval: $@\n";
  }
  # run the 'which_preprocessor' sub, passing ( $doc, $index and $textsearch )
  my $preprocessor = eval { $textsearch->{_comma_compiled_which_preprocessor}
                              ->( $doc, $self, $textsearch ) };
  if ( $@ ) {
    die "textsearch '" . $textsearch->element('name')->get() .
      "' died during its which_preprocessor routine: $@\n";
  }
  # run the stem() method of the returned preprocessor
  return $preprocessor->
    stem ( $doc->auto_dispatch($textsearch->element('name')->get()) );
}

sub sync_deferred_textsearches {
  my $self = shift();
  foreach my $textsearch ( $self->elements('textsearch') ) {
    # declare 'grp', a data structure that will group the records by
    # doc_id, and allow us to peform the minimum necessary action for
    # each doc_id in the table. (the records are returned in insertion
    # order, and we'll use that to figure out what has to be done for
    # each doc.)
    # $grp->{ <id> }-> [ { seq=>, action=>, _sq=>, frozen_text=> }, ... ]
    my $grp = {};
    # declare 'words', a data structure that holds the inverted index
    # pieces that are created for the deferred docs.
    # $words->{ <word> }-> [ doc_id, doc_id, doc_id ... ]
    my $words = {};
    # get the defers_table name
    my ( $i_table_name, $d_table_name ) = $self->sql_get_textsearch_tables
    ( $textsearch->element('name')->get() );

    # dbg ( "textsearch tables", $i_table_name, $d_table_name );
    # group
    my $sth = $self->sql_get_textsearch_defers_sth ( $d_table_name );
    while ( my $row = $sth->fetchrow_arrayref() ) {
      push @{$grp->{$row->[0]}}, { action      => $row->[1],
                                   _sq         => $row->[2],
                                   frozen_text => $row->[3] };
    }
    # now go through the ids and decide whether to del, del/upd, or just upd
    foreach my $id ( keys %{$grp} ) {
      # first, remove all of the entries that we've pulled from the
      # defers table
      $self->sql_delete_from_textsearch_defers_table ( $d_table_name,
                                                $id, $grp->{$id}->[-1]->{_sq} );

      if ( $grp->{$id}->[-1]->{action} == 1 ) {  # (delete action const is 1)
        # case 1 - last entry is 'delete': just delete
        $self->sql_delete_from_textsearch_index_table ( $i_table_name, $id );
      } else {
        if ( grep { $_->{action} == 1 } @{$grp->{$id}} ) {
          # case 2 - last entry is 'update' and there are previous 'deletes':
          #  delete then update
          $self->sql_delete_from_textsearch_index_table ( $i_table_name, $id );
          $self->_textsearch_cache_text ( $textsearch,
                                          $id,
                                          $words,
                                          $grp->{$id}->[-1]->{frozen_text} );
        } else {
          # case 3 - last entry is 'update' and there are no previous 'deletes':
          #  just update
          $self->_textsearch_cache_text ( $textsearch,
                                          $id,
                                          $words,
                                          $grp->{$id}->[-1]->{frozen_text} );
        }
      }
    }
    # do textsearch updates from cache
    foreach my $word ( keys %{$words} ) {
      $self->sql_update_in_textsearch_index_table ( 
                                             $i_table_name,
                                             $word,
                                             undef,   # doc_id
                                             0,       # clobber
                                             @{$words->{$word}} );
    }
  }
}

# this will, of course, take a long time on a big index
sub clean_textsearches {
  my $self = shift();
  foreach my $textsearch ( $self->elements('textsearch') ) {
    # data structure for caching seq number, so we don't have to go to
    # the database each and ever time.
    my %cached;  # each key is a sequence, 1 = not-in-data, 2 = in-data
    my ( $i_table_name ) = $self->sql_get_textsearch_tables
      ( $textsearch->element('name')->get() );
    my @words = $self->sql_get_textsearch_indexed_words ( $i_table_name );
    print "processing " . scalar(@words) . " entries for textsearch '" .
      $textsearch->element('name')->get() . "'\n";
    my $count;
    foreach my $word ( @words ) {
      unless ( $count++ % 500 ) { print "($count)." };
      my $altered;
      my %seqs = map { $_=>1 }
        unpack ( "l*",
                 $self->sql_get_textsearch_index_packed($i_table_name, $word) );
      foreach my $s ( keys %seqs ) {
        if ( ! defined $cached{$s} ) {
          $cached{$s} = $self->sql_seq_indexed_p ( $s );
        }
        if ( ! $cached{$s} ) {
          $altered = 1;
          delete $seqs{$s};
        }
      }
      if ( $altered ) {
        # dbg 'clobbering', $word, keys(%seqs);
        $self->sql_update_in_textsearch_index_table ( 
                                               $i_table_name,
                                               $word,
                                               undef,
                                               1, # clobber
                                               keys(%seqs) );
      }
    }
    print "\n";
  }
}

sub _textsearch_cache_text {
  my ( $self, $textsearch, $doc_id, $words, $frozen_text ) = @_;
  my ( $seq ) = $self->sql_get_sq_from_data_table ( $doc_id );
  return if ! $seq;
  #TODO: is this right or should it have been if($frozen_text) ?
  #kind of a moot point, but it'd be nice to clean this someday.
  if(thaw($frozen_text)) {
    foreach my $word ( @{thaw($frozen_text)} ) {
      push @{$words->{$word}}, $seq;
    }
  }
}

# call with no args to clean the data table and all binary tables. Or
# call with a table_name + sort_name
sub _maybe_clean {
  my ( $self, $sort_table_name, $sort_name ) = @_;

  my $trigger;
  my $table_name;
  my $clean_arg;

  if ( $sort_table_name ) {
    my ( $clean_element ) =
      $self->get_collection($sort_name)->elements ( 'clean' );
    return  if  ! $clean_element;
    $trigger = $clean_element->element('size_trigger')->get();
    $clean_arg = $table_name = $sort_table_name;
   } else {
    my ( $clean_element ) = $self->elements ( 'clean' );
    return  if  ! $clean_element;
    $trigger = $clean_element->element('size_trigger')->get();
    $table_name = $self->data_table_name();
  }

  return  if  ! $trigger;
  if ( $self->sql_simple_rows_count($table_name) >= $trigger ) {
    $self->clean ( $clean_arg );
  }
}

sub _check_db {
  my $self = shift();
  # get a checkdb_hold -- this makes startup for any given process
  # slightly slower, but should prevent multiple threads that are
  # starting up together from stepping on each other as they try to
  # create the necessary index tables.
  XML::Comma::lock_singlet()->wait_for_hold ( "CHECKDB_HOLD" );
  eval {
    # go ahead and try to create the index_tables table -- we'll just
    # assume that any error the database throws is just letting us know
    # that there's already a table here.
    eval { $self->sql_create_index_tables_table( ); };
    #if ( $@ ) { warn "$@\n"; }

    # see if there is an entry for this index's data table.
    my $old_def = _get_def_from_db ( $self );
    $self->_check_tables ( $old_def );
    # finally, release the hold.
  }; my $err = $@;
  XML::Comma::lock_singlet()->release_hold ( "CHECKDB_HOLD" );
  if ( $err ) { die $err; };
}

sub _get_def_from_db {
  my $self = shift();
  my $def_string = $self->sql_get_def();
  # Doc-ify
  my $def;
  if ( $def_string ) {
    # FIX: we could eval here and treat errors as if there is no def
    # -- we don't want to die here, we want to let callers of this
    # routine proceed as if they need to re-do stuff. unfortunately,
    # this means making other stages in table creation graceful, as
    # well.
    $def = XML::Comma::Def->new
      ( block => "<DocumentDefinition><name>_Comma_Index_InSitu_Def</name>
                  $def_string</DocumentDefinition>" )->
                    get_index ( $self->element('name')->get() );
  }
  return $def;
}

sub _check_tables {
  my ( $self, $old_def ) = @_;
  if ( ! $old_def ) {
    # if we don't get a def string back at all, we should assume we
    # are initializing everything, and need to create a new data table and
    # store ourself as a string in the info table
    #dbg 'creating data table', $self->name();
    $self->_create_new_data_table();
  } elsif ( $old_def->to_string() ne $self->to_string() ) {
    # dbg "old def and new def are not the same", $self->name();
    # store the new def in the info table, so we'll have it next time
    #dbg 'storing def in info table', $self->name();
    $self->sql_update_def_in_tables_table();
    # now compare the old def fields, collections and sql_indexes
    $self->_check_doctype_store ( $old_def );
    $self->_check_fields ( $old_def );
    $self->_check_collections ( $old_def );
    $self->_check_data_table_sql_indexes ( $old_def );
    $self->_check_textsearches ( $old_def );
  } else {
    #dbg "old def and new def match", $self->name();
  }
}

sub _check_doctype_store {
  my ( $self, $old_def ) = @_;
  my $has = 1 if $self->element('index_from_store')->get();
  my $old_has = 1 if $old_def->element('index_from_store')->get();
  if ( $has and !$old_has ) {
    $self->sql_alter_data_table_add( 'doctype', 'VARCHAR(255) NOT NULL' );
    $self->sql_alter_data_table_add( 'store', 'VARCHAR(255) NOT NULL' );
    $self->sql_alter_data_table_change_primary_key( qw(doctype store) );
  } 
  if ( !$has and $old_has ) {
    $self->sql_alter_data_table_drop_or_modify( 'doctype' );
    $self->sql_alter_data_table_drop_or_modify( 'store' );
  } 
}

sub _check_fields {
  my ( $self, $old_def ) = @_;
  #  build a hash of the new fields by name and type
  my %new_fields = map {
    ( $_->element('name')->get(),
      $_->element('sql_type')->get() ) } $self->elements('field');
  my %old_fields;
  if ( $old_def ) {
    %old_fields = map {
      ( $_->element('name')->get(),
        $_->element('sql_type')->get() ) } $old_def->elements('field');
  }
  #  drop any old fields that aren't present in the new def
  foreach my $name ( keys %old_fields ) {
    if ( ! defined $new_fields{$name} ) {
      $self->sql_alter_data_table_drop_or_modify ( $name );
    }
  }
  #  check each new field against the old ones
  foreach my $name ( keys %new_fields ) {
    if ( ! defined $old_fields{$name} ) {
      #dbg 'adding', $name;
      $self->sql_alter_data_table_add ( $name, $new_fields{$name} );
    } elsif ( $old_fields{$name} ne $new_fields{$name} ) {
      #dbg 'altering', $name;
      $self->sql_alter_data_table_drop_or_modify ( $name, $new_fields{$name} );
    } else {
      #dbg 'unchanged', $name;
    }
  }
}

sub _check_collections {
  my ( $self, $old_def ) = @_;
  my %new_collections =
    map { ($_->element('name')->get(), $_) }
      ($self->elements('collection'),
       $self->elements('sort'));
  my %old_collections;
  if ( $old_def ) {
    %old_collections =
      map { ($_->element('name')->get(), $_) }
        ($old_def->elements('collection'),
         $old_def->elements('sort'));
  }
  # drop any old collections that aren't in the new def or that have
  # changed their type or fields
  while ( my ($name,$el) = each %old_collections ) {
    my $type = $el->element('type')->get();
    next  if  $type eq 'many tables';
    my $new_field_hash =
      ( exists $new_collections{$name} &&
        @{$new_collections{$name}->elements('field')} ?
        $new_collections{$name}->element('field')->comma_hash : 0 );
    my $el_field_hash =
      ( @{$el->elements('field')} ?
        $el->element('field')->comma_hash : 0 );

    unless ( (defined $new_collections{$name} and
              $type eq $new_collections{$name}->element('type')->get()) and
             $new_field_hash eq $el_field_hash ) {
      #dbg 'dropping old collection', $name, $type, $sql_type;
      if ( $type eq 'stringified' ) {
        $self->sql_alter_data_table_drop_or_modify ( $name );
      } elsif ( $type eq 'binary table' ) {
        $self->sql_drop_bcollection_table ( $name );
      }
    }
  }
  # add any new collections that aren't in the old def or that have
  # changed their type
  while ( my ($name,$el) = each %new_collections ) {
    my $type = $el->element('type')->get();
    next  if  $type eq 'many tables';
    my $old_field_hash =
      ( exists $old_collections{$name} &&
        @{$old_collections{$name}->elements('field')} ?
        $old_collections{$name}->element('field')->comma_hash : 0 );
    my $el_field_hash =
      ( @{$el->elements('field')} ?
        $el->element('field')->comma_hash : 0 );

    unless ( (defined $old_collections{$name} and
              $type eq $old_collections{$name}->element('type')->get()) and
             $old_field_hash eq $el_field_hash ) {
      #dbg 'adding new collection', $name, $type, $el_field_hash;
      if ( $type eq 'stringified' ) {
        $self->sql_alter_data_table_add_collection ( $name );
      } elsif ( $type eq 'binary table' ) {
        $self->sql_create_bcollection_table ( $name, $el );
      }
    }
  }
}

sub _check_data_table_sql_indexes {
  my ( $self, $old_def ) = @_;
  my %new_indexes =
    map { ($_->element('name')->get(), $_) } $self->elements('sql_index');
  my %old_indexes;
  if ( $old_def ) {
    %old_indexes =
      map { ($_->element('name')->get(), $_) } $old_def->elements('sql_index');
  }
  # drop any old indexes that aren't in the new def, or that have changed
  foreach my $name ( keys %old_indexes ) {
    if (! defined $new_indexes{$name} or
        $new_indexes{$name}->to_string() ne $old_indexes{$name}->to_string()) {
      #dbg 'dropping old/changed index', $name;
      $self->sql_alter_data_table_drop_index ( $name );
    }
  }
  # add any new collections that aren't in the old, or that have changed
  foreach my $name ( keys %new_indexes ) {
    if (! defined $old_indexes{$name} or
        $new_indexes{$name}->to_string() ne $old_indexes{$name}->to_string()) {
      #dbg 'adding new/changed index', $name;
      $self->sql_alter_data_table_add_index ( $new_indexes{$name} );
    }
  }
}

sub _check_textsearches {
  my ( $self, $old_def ) = @_;
  my %new_tses =
    map { ($_->element('name')->get(), $_) } $self->elements('textsearch');
  my %old_tses;
  if ( $old_def ) {
    %old_tses =
      map { ($_->element('name')->get(), $_) } $old_def->elements('textsearch');
  }
  # drop any old textsearches that aren't in the new def, or that have changed
  foreach my $name ( keys %old_tses ) {
    if (! defined $new_tses{$name} or
        $new_tses{$name}->to_string() ne $old_tses{$name}->to_string()) {
      #dbg 'dropping old/changed ts', $name;
      $self->sql_drop_textsearch_tables ( $name );
    }
  }
  # add any new textsearches that aren't in the old, or that have changed
  foreach my $name ( keys %new_tses ) {
    if (! defined $old_tses{$name} or
        $new_tses{$name}->to_string() ne $old_tses{$name}->to_string()) {
      #dbg 'adding new/changed ts', $name;
      $self->sql_create_textsearch_tables ( $new_tses{$name} );
    }
  }
}

#  # FIX!!!!!
#  sub _check_bcollections {
#    my ( $self, $old_def ) = @_;
#    my %new_collections =
#      map { ($_->element('name')->get(), $_) } $self->elements('bcollection');
#    my %old_collections;
#    if ( $old_def ) {
#      %old_collections =
#        map { ($_->element('name')->get(), $_)} $old_def->elements('bcollection');
#    }
#    # drop any old collections that aren't in the new def, or that have changed
#    foreach my $name ( keys %old_collections ) {
#      if (! defined $new_collections{$name} or
#          $new_collections{$name}->to_string() ne
#          $old_collections{$name}->to_string()) {
#        #dbg 'dropping old/changed bcol', $name;
#        sql_drop_bcollection_table ( $self, $name );
#      }
#    }
#    # add any new textsearches that aren't in the old, or that have changed
#    foreach my $name ( keys %new_collections ) {
#      if (! defined $old_collections{$name} or
#          $new_collections{$name}->to_string() ne 
#          $old_collections{$name}->to_string()) {
#        #dbg 'adding new/changed bcol', $name;
#        sql_create_bcollection_table ( $self, $new_collections{$name} );
#      }
#    }
#  }


# creates a new data table. optional argument $existing_table_name is
# used to *re-create* a data table that needs its definition altered
# (since certain brain-dead databases don't support full SQL ALTER
# stuff.)
sub _create_new_data_table {
  my ( $self, $existing_table_name ) = @_;
  $self->sql_create_data_table ( $existing_table_name );
  my $ifs = $self->element('index_from_store')->get(); 
  if ( $ifs ) {
    my $type = 'VARCHAR(255) NOT NULL'; 
    my @columns = qw( doctype store );
    foreach my $column ( @columns ) {
      $self->sql_alter_data_table_add ( $column, $type );
    }
    $self->sql_alter_data_table_change_primary_key( @columns );
  }
  foreach my $field ( $self->elements('field') ) {
    my $name = $field->element('name')->get();
    my $type = $field->element('sql_type')->get();
    $self->sql_alter_data_table_add ( $name, $type );
  }
  foreach my $collection ( $self->elements('collection') ) {
    my $name = $collection->element('name')->get();
    my $type = $collection->element('type')->get();
    if ( $type eq 'stringified' ) {
      $self->sql_alter_data_table_add_collection ( $name );
    } elsif ( $type eq 'binary table' ) {
      $self->sql_create_bcollection_table ( $name, $collection );
    }
  }
  foreach my $sql_index ( $self->elements('sql_index') ) {
    $self->sql_alter_data_table_add_index ( $sql_index );
  }
  if ( ! $existing_table_name ) {
    foreach my $textsearch ( $self->elements('textsearch') ) {
      $self->sql_create_textsearch_tables ( $textsearch );
    }
  }
}

sub DESTROY {
  # disconnect database handle
  $_[0]->disconnect();
}


1;
