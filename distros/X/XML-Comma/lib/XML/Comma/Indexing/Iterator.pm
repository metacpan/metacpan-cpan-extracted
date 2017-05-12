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

package XML::Comma::Indexing::Iterator;

use vars '$AUTOLOAD';

@ISA = ( 'XML::Comma::SQL::DBH_User' );

use XML::Comma::Util qw( dbg arrayref_remove );
use XML::Comma::SQL::DBH_User;

use strict;

use overload bool => \&iterator_has_stuff,
  '""' => sub { return $_[0] },
  '++' => \&iterator_next,
  '='  => sub {
    # dbg '=', "-> $_[0]"; 
    #
    # this is problematic, because of an apparent scoping bug in perl
    # 5.6.1 and 5.8.0.  Gotchas should be fully explained in
    # documentation.
    return $_[0];
  }
;

use Parse::RecDescent;
my $spec_parser =
  Parse::RecDescent->new ( $XML::Comma::Indexing::Iterator::spec_grammar );

# _Iterator_index
# _Iterator_columns_pos     : {} column_name => pos
# _Iterator_columns_list     : [] column names

# _Iterator_from_tables : [] of tables to select from, includes data table and
#                         whatever is in the sort_spec and textsearch_spec
# _Iterator_data_table_aliased : table_alias/undef   tells us if the data tables 
#                                have been aliased by a binary_table collection_spec.
# _Iterator_where_clause
# _Iterator_order_by
# _Iterator_order_expressions : [] of expression elements that are used by
#                                     order by and so need to be part of the
#                                     select statement

# _Iterator_collection_spec  : SQL string created from collection_spec arg
# _Iterator_textsearch_arg
# _Iterator_textsearch_spec  : SQL string created from textsearch_spec arg
# _Iterator_stopwords        :      stopwords found for a textsearch
# _Iterator_notfoundwords           textsearch words with no entries
# _Iterator_textsearch_temp_tables : what temp tables did we make for ts's

# _Iterator_st
# _Iterator_current_row
# _Iterator_select_returnval : whatever value the select statement statement
#                              returned. (MySQL seems to return the total
#                              number of rows, which is useful.) 
# _Iterator_select_count   : for a database like MySQL that will give
#                            us the number of rows returned by our select,
#                            we cache that value here, but only for non-limit
#                            calls.
#
# _Iterator_newly_created
# _Iterator_newly_refreshed
#
# _Iterator_distinct : flag turned on when sql generation routines recognize
#                    : that a multi-way joing that may create duplicate rows
#                    : has been constructed.
#

sub new {
  my ( $class, %args ) = @_;
  my $self = {};
  eval {
    bless ( $self, $class );
    $self->{_Iterator_index} = $args{index} ||
      die "need an Indexing::Index reference to make an Iterator\n";
    $self->{_Iterator_order_by} = $args{order_by} || '';
    $self->{_Iterator_where_clause} = $args{where_clause} || '';
    $self->{_Iterator_having_clause} = $args{having_clause} || '';
    $self->{_Iterator_from_tables} =
      [ $self->{_Iterator_index}->data_table_name() ];

    ( $self->{_Iterator_columns_lst}, $self->{_Iterator_columns_pos} ) =
      $self->_make_columns_lsts ( $args{fields} );

    my $cspec_arg;
    if ( $args{collection_spec} and $args{sort_spec} ) {
      $cspec_arg = "$args{collection_spec} AND $args{sort_spec}";
    } else {
      $cspec_arg = $args{collection_spec} || $args{sort_spec};
    }
    $self->{_Iterator_collection_spec} =
      $self->_make_collection_spec( $cspec_arg );

    $self->{_Iterator_textsearch_arg} = $args{textsearch_spec};

    # this 'distinct' arg isn't documented, because I'm not sure
    # why/how it might be used at the API level
    if ( defined $args{distinct} ) {
      $self->{_Iterator_distinct} = $args{distinct};
    }

    # after all of the different parts of the SQL spec have been set up, check
    # and see if we need to munge the where_clause.  For instance, if we
    # aliased the data table name for a binary collection_spec join using
    # doc_id, and we have doc_id specified in our where_clause, we need to try
    # to alias doc_id to t01.doc_id.
    $self->_possibly_munge_where_clause();

    $self->{_Iterator_newly_created} = 1;
    #  dbg 'i-spec', $self->{_Iterator_sort_spec};
  }; if ( $@ ) { XML::Comma::Log->err ( 'BAD_ITERATOR_CREATE', $@ ); }
  return $self;
}


sub count_only {
  my ( $class, %args ) = @_;
  my $sth;
  my $self;
  if ( ref $class ) {
    $self = $class;
    eval { $self->_make_textsearch_spec(); }; if ( $@ ) { 
      XML::Comma::Log->err ( 'ITERATOR_ACCESS_FAILED', $@ );
    }
  } else {
    $self = $class->new ( %args );
    eval {
      ( $self->{_Iterator_textsearch_spec},
        $self->{_Iterator_stopwords},
        $self->{_Iterator_notfoundwords} ) = $self->_make_textsearch_spec();
    }; if ( $@ ) { 
      XML::Comma::Log->err ( 'ITERATOR_ACCESS_FAILED', $@ );
    }
  }
  eval {
    my $order_by = $self->_fill_order_expressions();
    my $string = $self->sql_select_from_data
      ( $self->{_Iterator_index},
        $self->{_Iterator_order_expressions},
        $self->{_Iterator_from_tables},
        $self->{_Iterator_where_clause},
        $self->{_Iterator_having_clause},
        $self->{_Iterator_distinct},
        $order_by,
        0, 0,
        [],   # columns list
        $self->{_Iterator_collection_spec},
        $self->{_Iterator_textsearch_spec},
        'do count only' );
    # dbg 'count_only', $string;
    $sth = $self->{_Iterator_index}->get_dbh_reader()->prepare ( $string );
    $sth->execute();
  }; if ( $@ ) { 
    XML::Comma::Log->err ( 'ITERATOR_ACCESS_FAILED', $@ );
  }
  my $ret = $sth->fetchrow_arrayref()->[0];
  $sth->finish();
  return $ret;
}


sub aggregate {
  my ( $class, %args ) = @_;
  my $function = $args{function} || die "need a function to aggregate\n";
  my $sth;
  my $self = $class->new ( %args );
  eval {
    my $order_by = $self->_fill_order_expressions();
    ( $self->{_Iterator_textsearch_spec},
      $self->{_Iterator_stopwords},
      $self->{_Iterator_notfoundwords} ) = $self->_make_textsearch_spec();
    my $string = $self->sql_select_from_data
      ( $self->{_Iterator_index},
        $self->{_Iterator_order_expressions},
        $self->{_Iterator_from_tables},
        $self->{_Iterator_where_clause},
        $self->{_Iterator_having_clause},
        $self->{_Iterator_distinct},
        $order_by,
        0, 0, # limits
        [],   # columns list
        $self->{_Iterator_collection_spec},
        $self->{_Iterator_textsearch_spec},
        '',   # count only
        $function );
   # dbg 'aggregate', $string;
    $sth = $self->{_Iterator_index}->get_dbh_reader()->prepare ( $string );
    $self->{_Iterator_select_returnval} = $sth->execute();
  }; 
  if ( $@ ) { 
    XML::Comma::Log->err ( 'ITERATOR_ACCESS_FAILED', $@ ); 
  }
  my $ret = $sth->fetchrow_arrayref()->[0];
  $sth->finish();
  return $ret;
}

sub distinct_field_values {
  my ( $class, %args ) = @_;
  my $self = $class->new ( %args );
  my $sth;
  eval {
    my $order_by = $self->_fill_order_expressions();
    $sth = $self->sql_select_distinct_field
      ( $self->{_Iterator_index},
        $args{_field_name},
        $self->{_Iterator_where_clause},
      );
  };
  if ( $@ ) { 
    XML::Comma::Log->err ( 'ITERATOR_ACCESS_FAILED', $@ ); 
  }
  $sth->execute();
  my $result = $sth->fetchall_arrayref([0]);
  return map { $_->[0] } @$result;
}

sub iterator_refresh {
  my ( $self, $limit_number, $limit_offset ) = @_;
  eval {
    my $order_by = $self->_fill_order_expressions();
    $self->_make_textsearch_spec();
    my $index = $self->{_Iterator_index};
    my $dbh = $index->get_dbh_reader();
    $self->{_Iterator_sth}->finish()  if  $self->{_Iterator_sth};
    my $string = $self->sql_select_from_data (
       $self->{_Iterator_index},
       $self->{_Iterator_order_expressions},
       $self->{_Iterator_from_tables},
       $self->{_Iterator_where_clause},
       $self->{_Iterator_having_clause},
       $self->{_Iterator_distinct},
       $order_by,
       $limit_number,
       $limit_offset,
       $self->{_Iterator_columns_lst},
       $self->{_Iterator_collection_spec},
       $self->{_Iterator_textsearch_spec} 
    );
    #dbg 'refreshing', $self;
    # dbg 'sql', $string;
    $self->{_Iterator_sth} = $dbh->prepare ( $string );
    $self->{_Iterator_select_returnval} = $self->{_Iterator_sth}->execute();
    if ( $self->sql_select_returns_count  and
         ! defined $limit_number and ! defined $limit_offset ) {
      $self->{_Iterator_select_count} = $self->{_Iterator_select_returnval};
    } else {
      $self->{_Iterator_select_count} = undef;
    }
    #  dbg 'srv', $self->{_Iterator_select_returnval};
    #  dbg 'res', $self->{_Iterator_sth}->dump_results(); exit(0);
    $self->{_Iterator_newly_created} = 0;
    $self->{_Iterator_newly_refreshed} = 1;
    $self->{_Iterator_current_row} = undef;
  }; if ( $@ ) { XML::Comma::Log->err ( 'ITERATOR_ACCESS_FAILED', $@ ); }
  return $self;
}

sub iterator_next {
  my $self = shift();
  if ( $self->{_Iterator_newly_created} ) {
    $self->iterator_refresh();
  }
  $self->{_Iterator_newly_refreshed} = 0;
  eval {
    $self->{_Iterator_current_row} =
      $self->{_Iterator_sth}->fetchrow_arrayref(); 
  }; #if ( $@ ) { XML::Comma::Log->err ( 'ITERATOR_ACCESS_FAILED', $@ ); }
  # it actually seems better not to do anything with errors here. that
  # we we can run under raise_error, and still multiply-advance past
  # the end of an iterator sequence. if there is an actual database
  # error, presumably it will get thrown again next time any fields
  # are asked for.
  return  $self->{_Iterator_current_row} ? $self : 0;
}

sub iterator_has_stuff {
  my $self = shift();
  # as with _current_element (which this could be factored into) check
  # to see if we're newly created or newly refreshed, and need to
  # transparently setup to retrieve elements (dwim in action)
  if ( $self->{_Iterator_newly_created} ) {
    $self->iterator_refresh();
  }
  if ( $self->{_Iterator_newly_refreshed} ) {
    $self->iterator_next();
  }
  return $self->{_Iterator_current_row} ? 1 : 0;
}

sub select_count {
  my $self = shift;
  if ( defined $self->{_Iterator_select_count} ) {
    return $self->iterator_select_returnval;
  } else {
    return $self->count_only();
  }
}

sub iterator_select_returnval {
  unless ( defined $_[0]->{_Iterator_select_returnval} ) {
    $_[0]->iterator_refresh();
  }
  return $_[0]->{_Iterator_select_returnval};
}

sub textsearch_stopwords {
  return @{$_[0]->{_Iterator_stopwords} || []};
}

sub textsearch_not_found {
  return @{$_[0]->{_Iterator_notfoundwords} || []};
}

sub retrieve_doc {
  my ($self, %args) = @_;
  return XML::Comma::Doc->retrieve( $self->doc_key(), %args );
}

sub read_doc {
  my ($self, %args) = @_;
  return $self->{_Iterator_doc_cache}->{$self->doc_key} || 	 
    XML::Comma::Doc->read( $self->doc_key(), %args ); 	 
}

# alias doc_(read && retrieve) to (read && retrieve)_doc 
# for API consistancy

*doc_retrieve = \&retrieve_doc;
*doc_read     = \&read_doc;
  
sub doc_key {
  my $self = shift();
  # if we're working on an index with <index_from_store> look
  # to the database for the doctype/store
  my ( $type, $store );
  if ( $self->{_Iterator_index}->element( 'index_from_store' )->get() ) {
    $type  = $self->doctype();
    $store = $self->store();
  } else {
    $type  = $self->{_Iterator_index}->doctype();
    $store = $self->{_Iterator_index}->store();
  }
  return XML::Comma::Storage::Util->_concat_key
    ( $type, $store, $self->doc_id() );
}

sub _current_element {
  my ( $self, $el_name ) = @_;
  # check to see if we're newly created or newly refreshed, and need
  # to transparently setup to retrieve elements (dwim in action)
  if ( $self->{_Iterator_newly_created} ) {
    $self->iterator_refresh();
  }
  if ( $self->{_Iterator_newly_refreshed} ) {
    $self->iterator_next();
  }
  return  if  ! $self->{_Iterator_current_row};
  my $pos = $self->_ce_pos ( $el_name );
  if ( defined $pos ) {
    my $value = $self->{_Iterator_current_row}->[ $pos ];
    if ( $self->{_Iterator_index}->column_type($el_name) eq 'collection' ) {
      my $list =
        $self->{_Iterator_index}->collection_stringify_unconcat ( $value );
      return wantarray ? @{$list} : $list;
    } else {
      return $value;
    }
  } else {
    die "no '$el_name' item available from iterator\n";
  }
}

# get the position in the select statement of a given 'column' name
sub _ce_pos {
  return 0 if $_[1] eq 'doc_id';
  return scalar ( @{$_[0]->{_Iterator_columns_lst}} ) + 1
      if $_[1] eq 'record_last_modified';
  return $_[0]->{_Iterator_columns_pos}->{$_[1]};
}

sub _make_columns_lsts {
  my ( $self, $fields_arg ) = @_;
  my $array_ref;
  if ( defined $fields_arg ) {
    $array_ref = [ @$fields_arg ];
    arrayref_remove ( $array_ref, 'doc_id', 'record_last_modified' );
    # check to make sure these are all legal columns
    foreach my $col ( @$array_ref ) {
      die "no such field as '$col' known\n"  unless
        $self->{_Iterator_index}->column_type($col);
    }
  } else {
    $array_ref = [ $self->{_Iterator_index}->columns() ];
  }
  my $i=1;
  my %pos_hash = map { $_ => $i++ } @$array_ref;
  return ( [ @$array_ref ], { %pos_hash } );
}

# first runs _get_order_by to get the order_by expression, and then
# loops to check whether various order_by_expressions are being
# referenced. pushes the <order_by_expression> elements that it finds
# onto the array.
sub _fill_order_expressions {
  my $self = shift();
  my $odb = $self->_get_order_by() || return '';
  $self->{_Iterator_order_expressions} = [];
  foreach my $exp ($self->{_Iterator_index}->elements('order_by_expression')) {
    # if the name of this exp appears in the order_by clause (as a
    # whole word), push this el onto our order_by_expressions array
    if ( $odb =~ m:\b${ \( $exp->element('name')->get() )}\b: ) {
      push @{$self->{_Iterator_order_expressions}}, $exp;
    }
  }
  return $odb;
}

# generate an order by clause -- use default_order_by if no order_by is given
sub _get_order_by {
  my $self = shift();
  my $order_by_string = "";
  unless ( $order_by_string = $self->{_Iterator_order_by} ) {
    $order_by_string =
      $self->{_Iterator_index}->element('default_order_by')->get();
  }
  # dbg 'odb', $order_by_string;
  return $order_by_string;
}

sub _make_collection_spec {
  my ( $self, $arg ) = @_;
  return '' if ! $arg;
  my $sql = '(';
  my $dtn = $self->{_Iterator_index}->data_table_name();
  my @from_tables;
  my @binary_tables;
  my @sort_tables;
  my $chunks = $spec_parser->statement ( $arg . " )END OF STATEMENT" );
  die "bad collection spec: '$arg'\n"  unless  $chunks;

  if ( $self->_is_binary_collection_spec($chunks) ) {
    return $self->_make_binary_collection_spec($chunks);
  }

  XML::Comma::Log->warn("Use of 'many tables' or 'stringified' collection types is deprecated") unless($XML::Comma::_no_deprecation_warnings);

  foreach my $chunk ( @{$chunks} ) {
    my $NOT = ''; my $OP = '=';
    my ( $name, $value) = split /:/, $chunk, 2;

    if ( $value ) {
      $NOT = 'NOT'  if  $name =~ s/NOT //;
      $OP = 'LIKE' if $value =~ /\%/;
      my ( $table_name, $type );
      $table_name =
        $self->{_Iterator_index}->collection_table_name ($name,$value);
      push ( @from_tables, $table_name )  if  $table_name;
      $type = $self->{_Iterator_index}->collection_type ( $name );

      if ( $type eq 'stringified' ) {
        if ( $OP eq 'LIKE' ) {
          # we only support partial matches that are "anchored" at the
          # beginning or the end.
          unless ( $value =~ /^\%/ or $value =~ /\%$/ ) {
            die "can only use front- or rear-anchored partial " .
              "matches with collection '$name'\n";
          }
        }
        my $partial =
          $self->{_Iterator_index}->collection_stringify_partial ( $value );
        $sql .= "$table_name.$name $NOT LIKE " .
          $self->{_Iterator_index}->get_dbh_reader()->quote ( "%$partial%" );

      } elsif ( $type eq 'binary table' ) {
        push @binary_tables, $table_name;
        die "can't use NOT with binary-tables-type collection '$name'\n"
          if $NOT;
        $sql .= "$table_name.value $OP " .
          $self->{_Iterator_index}->get_dbh_reader()->quote ( $value );
        # we need to set the _distinct flag, if we use a partial
        # match, here, as there could be multiple records in the
        # binary table that will get joined in.
        unless ( defined $self->{_Iterator_distinct} ) {
          $self->{_Iterator_distinct} = 1  if  $OP eq 'LIKE';
        }
        # finally, we'll need to make sure that we select for the
        # 'extra' table, mapping it (using a sequel "as") to the name
        # that its field was given in the def.
        my $field = $self->{_Iterator_index}->collection_field ( $name );
        if ( $field ) {
          $self->{_Iterator_distinct} = 1;
          push @{$self->{_Iterator_columns_lst}},
            [ $table_name, $field->element('name')->get ];
        }

      } elsif ( $type eq 'many tables' ) {
        die "can't use a partial (%) match with collection '$name'\n"
          if $OP eq 'LIKE';
        $OP = '!=' if $NOT;
        if ( $table_name ) {
          $sql .= "$dtn.doc_id" . $OP . "$table_name.doc_id";
          push @sort_tables, $table_name;
        } else {
          # we didn't get a table name, so we must have asked for a
          # sort table that is so empty it hasn't ever even been
          # created
          $sql .= '1' . $OP . '0';
        }
      }
    } else {
      # no ':' in chunk, so must be a paren or conjunction
      $sql .= " $chunk ";
    }
  }
  $sql .= ')';
  # push all the tables we've seen onto our object-level from_tables
  # array
  XML::Comma::Util::arrayref_remove_dups ( \@from_tables );
  XML::Comma::Util::arrayref_remove ( \@from_tables, $dtn );
  push @{$self->{_Iterator_from_tables}}, @from_tables;
  # make a little bit more sql for all the binary tables we've seen
  # and throw an error if we see any binary table more than once.
  my %seen;
  foreach my $btn ( @binary_tables ) {
    # die "can't use one binary-type collection twice in spec\n" if $seen{$btn}++;
    $sql .= " AND $dtn.doc_id=$btn.doc_id"  unless  $seen{$btn}++;
  }
  # if we have an OR in our sql clause and have dealt with any tables
  # other than the data table, then we need to select DISTINCT. This
  # can be overridden if we already have an explicit 0 in
  # $self->{_Iterator_distinct}, which would presumably come from an
  # instantiation argument.
  if ( (@binary_tables or @sort_tables) and $sql =~ / or /i ) {
    $self->{_Iterator_distinct} = 1 unless defined $self->{_Iterator_distinct};
  }

  # dbg 'collection sql', $sql;
  return $sql;
}

sub _is_binary_collection_spec {
  my ( $self, $chunks ) = @_;

  foreach my $chunk ( @{$chunks} ) {
    my ( $name, $value) = split /:/, $chunk, 2;
    if ( $value ) { # we're dealing with a table
      my $type = $self->{_Iterator_index}->collection_type ( $name );
      return unless defined($type) && ($type eq 'binary table');
    }
  }

  return 1;
}

sub _make_binary_collection_spec {
  my ( $self, $chunks ) = @_;

  my $sql = '(';
  my $dtn = $self->{_Iterator_index}->data_table_name();
  my @binary_tables;

  foreach my $chunk ( @{$chunks} ) {
    my $NOT = ''; my $OP = '=';
    my ( $name, $value) = split /:/, $chunk, 2;

    if ( $value ) {
      $NOT = 'NOT'  if  $name =~ s/NOT //;
      $OP = 'LIKE' if $value =~ /\%/;
      my ( $table_name, $type );
      $table_name =
        $self->{_Iterator_index}->collection_table_name ($name,$value);

      push @binary_tables, $table_name;
      die "can't use NOT with binary-tables-type collection '$name'\n"
        if $NOT;

      # use the aliased table name that we haven't created yet, in the form
      # of tNN.  remember that $dtn will be t01, so offset the sprintf.

      my $btn = 't' . sprintf( "%02d", scalar @binary_tables + 1 );
      $sql .= "$btn.value $OP " .
        $self->{_Iterator_index}->get_dbh_reader()->quote ( $value );
      # we need to set the _distinct flag, if we use a partial
      # match, here, as there could be multiple records in the
      # binary table that will get joined in.
      unless ( defined $self->{_Iterator_distinct} ) {
        $self->{_Iterator_distinct} = 1  if  $OP eq 'LIKE';
      }
      # finally, we'll need to make sure that we select for the
      # 'extra' table, mapping it (using a sequel "as") to the name
      # that its field was given in the def.
      my $field = $self->{_Iterator_index}->collection_field ( $name );
      if ( $field ) {
        $self->{_Iterator_distinct} = 1;
        push @{$self->{_Iterator_columns_lst}},
          [ $table_name, $field->element('name')->get ];
      }
    } else {
      # no ':' in chunk, so must be a paren or conjunction
      $sql .= " $chunk ";
    }
  }
  $sql .= ')';

  # clobber unaliased _Iterator_from_tables
  $self->{_Iterator_from_tables} = [];

  # and set up aliases
  push @{ $self->{_Iterator_from_tables} }, "$dtn AS t01";
  my $t_num = 1;
  foreach my $btn ( @binary_tables ) {
    $t_num++;
    push @{ $self->{_Iterator_from_tables} }, "$btn AS t" .
                                                 sprintf( "%02d", $t_num );
  }
  # make a little bit more sql for all the binary tables to help mysql out
  # with the matrix
  $t_num = 1;
  foreach my $btn ( @binary_tables ) {
    $t_num++;
    $sql .= " AND t01.doc_id=t" . sprintf( "%02d", $t_num ) . ".doc_id";
  }

  # let others know that our from_tables are aliased now, so that things 
  # such as future self joining for textsearches still works.
  $self->{_Iterator_data_table_aliased} = 't01';

  # if we have an OR in our sql clause and have dealt with any tables
  # other than the data table, then we need to select DISTINCT. This
  # can be overridden if we already have an explicit 0 in
  # $self->{_Iterator_distinct}, which would presumably come from an
  # instantiation argument.
  if ( $sql =~ / or /i ) {
    $self->{_Iterator_distinct} = 1 unless defined $self->{_Iterator_distinct};
  }

  # dbg 'collection sql', $sql;
  return $sql;
}

# FIX: should a single term with no matches should stop the search,
# ala google?
# 
# This code counts on _make_collection_spec having been already executed.  A binary_table
# collection spec will have aliased the data_table_name.  We follow suit.
sub _make_textsearch_spec {
  my $self = shift;
  # don't do anything if we already have made temp tables -- reuse the
  # old ones. This might not work, as the temp tables could have
  # disappeared, although I'm not sure why this might happen,
  # yet. Anyway, initialize our scratchpad array of created temp
  # tables
  if ( $self->{_Iterator_textsearch_temp_tables} ) {
    return;
  } else {
    $self->{_Iterator_textsearch_temp_tables} = [];
  }

  # don't do anything if we don't have a textsearch arg
  unless ( $self->{_Iterator_textsearch_arg} ) {
    ( $self->{_Iterator_textsearch_spec},
      $self->{_Iterator_stopwords},
      $self->{_Iterator_notfoundwords} ) =
        ( '', [], [] ) unless $self->{_Iterator_textsearch_arg};
    return;
  }

  my @stopwords;
  my @notfoundwords;
  my $dbh = $self->{_Iterator_index}->get_dbh_reader();

  # check to see if we've aliased the data table previously in a 
  # _make_binary_collection_spec call
  my $data_table_name = $self->{_Iterator_data_table_aliased}; 
  # or get the actual table name.
  $data_table_name ||= $self->{_Iterator_index}->data_table_name();

  my $sql_string='';
  my @temp_tables;
  my ( $ts_name, $word_string ) =
    split ( /\:/, $self->{_Iterator_textsearch_arg}, 2 );
  my $ts_attribute;
  if ( $ts_name =~ m:(.*)\{(.*)\}: ) {
    $ts_name = $1;
    $ts_attribute = $2;
  }
  my $preproc = $self->_get_textsearch_preprocessor ( $ts_name, $ts_attribute );
  foreach my $word ( split /\s+/, $word_string ) {
    next unless $word;
    my ($stemmed_word) = $preproc->stem ( $word );
    if ( ! $stemmed_word ) {
      # arg was stopword
      push @stopwords, $word;
      next;
    }
    my $q_word = $dbh->quote ( $stemmed_word );
    my ($ts_table_name) =
      $self->{_Iterator_index}->sql_get_textsearch_tables($ts_name);
    die "no textsearch table found for $ts_name\n" if ! $ts_table_name;
    my ($temp_table_name, $size) = 
      $self->{_Iterator_index}
           ->sql_create_textsearch_temp_table ($ts_table_name, $stemmed_word);
    if ( ! $temp_table_name ) {
      # arg record not found or empty
      push @notfoundwords, $word;
      next;
    }
    push @temp_tables, { name=>$temp_table_name, size=>$size };
  }
  if ( ! @temp_tables ) {
    # no usable words found in spec
    ( $self->{_Iterator_textsearch_spec},
      $self->{_Iterator_stopwords},
      $self->{_Iterator_notfoundwords} ) =
        ( '0=1', \@stopwords, \@notfoundwords );
    return( '0=1', \@stopwords, \@notfoundwords );
  }
  @temp_tables = sort { $a->{size} <=> $b->{size} } @temp_tables;
  # do the first part of the join pivot
  my $temp_table_name = $temp_tables[0]->{name};
  $sql_string .= " $data_table_name._sq=$temp_table_name.id";
  # and do any remaining parts of the join
  foreach my $i ( 1..$#temp_tables ) {
    my $last_temp_table_name = $temp_tables[$i-1]->{name};
    my $temp_table_name = $temp_tables[$i]->{name};
    $sql_string .= " AND $last_temp_table_name.id=$temp_table_name.id";
  }
  push @{$self->{_Iterator_textsearch_temp_tables}},
    map { $_->{name} } @temp_tables;
  push @{$self->{_Iterator_from_tables}},
    @{$self->{_Iterator_textsearch_temp_tables}};

  #dbg 'ts', $sql_string;
  #dbg 'st', @stopwords;
  #dbg 'nf', @notfoundwords;

  ( $self->{_Iterator_textsearch_spec},
    $self->{_Iterator_stopwords},
    $self->{_Iterator_notfoundwords} ) =
      ( $sql_string, \@stopwords, \@notfoundwords );
}

sub _get_textsearch_preprocessor {
  my ( $self, $ts_name, $ts_attribute ) = @_;
  foreach my $ts_el ( $self->{_Iterator_index}->elements('textsearch') ) {
    if ( $ts_el->name() eq $ts_name ) {
      my $code_ref = eval $ts_el->element('which_preprocessor')->get();
      if ( $@ ) {
        die "textsearch '$ts_name' died during eval: $@\n";
      }
      my $preprocessor = eval {
        $code_ref->( undef, $self->{_Iterator_index}, $ts_el, $ts_attribute );
      }; if ( $@ ) {
        die "textsearch '$ts_name' died during 'which_preprocessor': $@\n";
      }
      return $preprocessor;
    }
  }
  die "no textsearch '$ts_name' found in " .
    $self->{_Iterator_index}->tag_up_path() . "\n";
}

my $sql_op_or_space =  join "|", qw[ \s < > = <= >= \( \) ];
my $RE_doc_id_in_where = qq[(^|$sql_op_or_space)(doc_id)($sql_op_or_space)];
sub _possibly_munge_where_clause {
  my $self = shift;
  if ( $self->{_Iterator_data_table_aliased} and 
       $self->{_Iterator_where_clause} =~ m/$RE_doc_id_in_where/go ) {
      my $prev_where_clause = $self->{_Iterator_where_clause};
      $self->{_Iterator_where_clause} =~ s/$RE_doc_id_in_where/$1t01.$2$3/go;
      XML::Comma::Log->warn( 
        "ITERATOR_WARNING - remapping ambiguous column doc_id.  " . 
        "Consider aliasing doc_id to t01.doc_id in your where_clause."
      );
      XML::Comma::Log->warn(
        "ITERATOR_WARNING - original where_clause: $prev_where_clause " .
        "changed to " . $self->{_Iterator_where_clause}
      );
  }
}

sub _get_bcollection_as_method {
  my ($self, $col) = @_;
  my $index = $self->{_Iterator_index};
  my $btn = $index->sql_get_bcollection_table( $col );
  return $index->sql_get_values_from_bcollection( $self->doc_id, $btn );
}

####
# AUTOLOAD
#
#
####

sub AUTOLOAD {
  my ( $self, @args ) = @_;
  # strip out local method name and stick into $m
  $AUTOLOAD =~ /::(\w+)$/;  my $m = $1;
  return $self->iterator_dispatch ( $m, @args );
}

sub iterator_dispatch {
  my ( $self, $m, @args ) = @_;

  # we need to preserve calling context during this dispatch
  my ( $value, @value );
  my $wantarray = wantarray();

  # it's an index method
  if ( my $method = $self->{_Iterator_index}->get_method($m) ) {
    eval {
      if ( $wantarray ) {
        @value = $method->( $self, @args );
      } else {
        $value = $method->( $self, @args );
      }
    };
    XML::Comma::Log->err ( 'ITERATOR_ACCESS_FAILED', $@ ) if $@;
    $wantarray ? return @value : return $value;
  # do some extra sql to make binary table collections available to the 
  # iterators
  } elsif ( $self->{_Iterator_index}->{_Index_collections}->{$m} and 
            $self->{_Iterator_index}
                 ->{_Index_collections}->{$m}->{type} eq 'binary table' ) {
    eval {
      if ( $wantarray ) {
        @value = $self->_get_bcollection_as_method($m);
      } else {
        $value = $self->_get_bcollection_as_method($m);
      }
    };
    XML::Comma::Log->err ( 'ITERATOR_ACCESS_FAILED', $@ ) if $@;
    $wantarray ? return @value : return $value;
  } else {
    eval { 
      if ( $wantarray ) {
        @value = $self->_current_element($m);
      } else {
        $value = $self->_current_element($m);
      }
    };
#    if($@) { 
#      my $doc = $self->read_doc(slow => 1);
#      if ( $wantarray ) {
#        @value = $doc->_current_element($m);
#      } else {
#        $value = $doc->_current_element($m);
#      }
#    }
    XML::Comma::Log->err ( 'ITERATOR_ACCESS_FAILED', $@ ) if $@;
    $wantarray ? return @value : return $value;
  }
}

sub DESTROY {
#  dbg 'iterator destroy', $_[0],$_[0]->{_Iterator_index}||'<undef>';
  #  map { print "  $_ --> " . (${$_[0]}{$_} || '<undef>') . "\n" } keys(%{$_[0]});
  $_[0]->{_Iterator_sth}->finish()  if  $_[0]->{_Iterator_sth};
  $_[0]->sql_drop_any_temp_tables
    ( $_[0]->{_Iterator_index}, scalar($_[0]), @{$_[0]->{_Iterator_from_tables}} )  if  $_[0]->{_Iterator_index};
#  dbg 'done destroying iterator', $_[0]->{_Iterator_index}||'<undef>';
}

####

BEGIN {
$XML::Comma::Indexing::Iterator::spec_grammar = q{

statement: spec ")END OF STATEMENT" { $return = $item[1] } | <error>

spec:
       npair conj  spec { $return = [ $item[1], $item[2], @{$item[3]} ] }   |
       npair            { $return = [ $item[1] ] }                          |
       '(' spec ')' conj spec  
         { $return = [ '(', @{$item[2]}, ')', $item[4], @{$item[5]} ] }    |
       '(' spec ')'
         { $return = [ '(', @{$item[2]}, ')' ] }

conj: 'AND' | 'OR'

npair: 'NOT' pair { $return = 'NOT ' . $item[2] } | pair

pair: /\w+/ ":" /[^\s\)]+/                { $return = $item[1].':'.$item[3] } |
      "'" /\w+/ ":" /.+?(?<!\\\)(?=')/ "'"
        { my $value = $item[4]; $return = $item[2].':'.$item[4]; }

};
}


1;
