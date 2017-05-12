##
#
#    Copyright 2001-2005, AllAfrica Global Media
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

package XML::Comma::Indexing::Clean;

@ISA = ( 'XML::Comma::NestedElement',
         'XML::Comma::SQL::DBH_User' );

use XML::Comma::SQL::DBH_User; 
use XML::Comma::Util qw( dbg );

use Carp ();
use strict;

# what to stick in the _comma_flag slots while we work
my $clean_flag = 2;


# _Clean_order_by
# _Clean_data_table_name
# _Clean_table_name
# _Clean_sort_spec
# _Clean_in_progress
# _Clean_doctype
# _Clean_indexname

sub init_and_cast {
  my ( $class, %args ) = @_;
  my $self = $args{element} || die "need an element";
  $self->{_Clean_doctype} = $args{doctype};
  $self->{_Clean_indexname} = $args{index_name};
  $self->{_Clean_order_by} = $args{order_by};
  $self->{_Clean_table_name} = $args{table_name} || die "need a table name";
  $self->{_Clean_data_table_name} = $args{data_table_name};
  $self->{_Clean_bcollection_table_names} =
    $args{bcollection_table_names} || [];
  $self->{_Clean_sort_spec} = $args{sort_spec} || '';
  # populate $self->{ _DBH } and $self->{ _DBH_pid } so later we can call 
  # get_dbh() without the initial _connect() overhead.
  $self->{_DBH} = $args{dbh} and $self->{_DBH_pid} = $$;
  return XML::Comma::SQL::DBH_User::decorate_and_bless ( $self, $class );
}

sub clean {
  my $self = shift();
  my $dbh = $self->get_dbh_writer();
  my $order_by = $self->{_Clean_order_by};
  my $data_table_name = $self->{_Clean_data_table_name};
  my $table_name = $self->{_Clean_table_name};

  # prepare the erase where clause. we want to eval it if the first
  # character is a '{', otherwise, leave it alone
  my $ewc = $self->element('erase_where_clause')->get();
  my $erase_where_clause;
  if ( $ewc and $ewc =~ m|^\s*\{| ) {
    $erase_where_clause = eval $ewc;
    if ( $@ ) { die "error preparing erase_where_clause '$ewc': $@\n" }
  } else {
    $erase_where_clause = $ewc;
  }
  #dbg 'erase_wc', $erase_where_clause || "<undef>";

  # don't clean if table _comma flag is set
  if ( $self->sql_get_table_comma_flag($dbh, $table_name) ) {
    print "skipping clean on $table_name...";
    return;
  }
  $self->{_Clean_in_progress} = 1;
  # set table _comma flag
  $self->sql_set_table_comma_flag ( $dbh, $table_name, $clean_flag );
  # for table we care about: clear all _comma flags
  $self->sql_clear_all_comma_flags ( $dbh, $table_name );
  # first pass clean: for sort tables removes orphan entries, for both
  # sort and data tables removes rows matching any erase_where_clause
  $self->sql_set_comma_flags_for_clean_first_pass
    ( $dbh, $data_table_name, $table_name, $erase_where_clause, $clean_flag );
  $self->sql_delete_where_comma_flags ( $dbh, $table_name, $clean_flag );
  # second pass clean: arranges rows in order and removes rows above
  # our to_size limit
  if ( my $size_limit = $self->element('to_size')->get() ) {
    $self->sql_set_comma_flags_for_clean_second_pass
      ( $dbh,
        $table_name,
        $self->{_Clean_order_by},
        $self->{_Clean_sort_spec},
        $self->{_Clean_doctype},
        $self->{_Clean_indexname},
        $size_limit,
        $clean_flag );
    $self->sql_delete_where_comma_flags ( $dbh, $table_name, $clean_flag );
  }
  # and if we have any bcollection tables to clean, do them, too. it's
  # pretty kludgy to do this here rather than in a separate chunk of
  # code, but that's okay. at least we know everything's already set
  # up if we just go ahead and clean the bcollection tables inside our
  # data table clean "envelope". so we're not going to set the table
  # comma flags, etc. the sql looping in here also ought to be
  # combined with the nearly-identical loop in
  # sql_set_comma_flags_for_clean_second_pass. finally, we assume that
  # there are bcollection_table_names in our local slot only if this
  # Clean was created to work on the data table (but we don't check
  # that, to make sure). so our $table_name is the data table
  # name. (see, I told you it was kludgy)
  foreach my $bctn ( @{$self->{_Clean_bcollection_table_names}} ) {
    $self->sql_clear_all_comma_flags ( $dbh, $bctn );
    my $sth = $dbh->prepare ( $self->sql_clean_find_orphans ($bctn, $table_name) );
    $sth->execute();
    while ( my $row = $sth->fetchrow_arrayref() ) {
      my $orphan_id = $row->[0];
      $dbh->do ( "UPDATE $bctn SET _comma_flag=$clean_flag WHERE doc_id="
                 . $dbh->quote($orphan_id) );
    }
    $self->sql_delete_where_comma_flags ( $dbh, $bctn, $clean_flag );
  }
  # unset comma flag
  $self->sql_unset_table_comma_flag ( $dbh, $table_name );
  $self->{_Clean_in_progress} = 0;
}

sub DESTROY {
  my $self = shift();
  if ( $self->{_Clean_in_progress} ) {
    # un-set table _comma flag
    $self->sql_unset_table_comma_flag( $self->get_dbh_writer(),
                                $self->{_Clean_table_name} );
  }
}

1;
