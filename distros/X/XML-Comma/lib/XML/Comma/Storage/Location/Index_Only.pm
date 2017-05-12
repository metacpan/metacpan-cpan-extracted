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

package XML::Comma::Storage::Location::Index_Only;
use XML::Comma::Util qw( dbg );

use strict;

# _index_name :
# _doctype    :


sub new {
  my ( $class, %arg ) = @_; 
  my $self = {};
  bless ( $self, $class );
  unless ( $arg{decl_pos} == 0 ) {
    die "Index_Only Location module should be used only all by itself\n";
  }

  $self->{_index_name} = $arg{index_name} ||
    die "Index_Only Location module needs an index_name argument\n";
  $self->{_doctype} = $arg{store}->doctype();

  # In special cases where we don't want doc_ids to be sequential we 
  # allow the use to specify an element or method to derive the doc_id
  # from
  $self->{_IO_derive_from} = $arg{derive_from};
  # derive_args (experimental)
  $self->{_IO_derive_args} = $arg{derive_args} || [];

  my $index = XML::Comma::Def->read ( name=>$self->{_doctype} )
    ->get_index ( $self->{_index_name} ) ||
    die "Index_Only error -- can't get index named $arg{index_name} for doctype '$arg{store}\n";
  $index->element('doc_id_sql_type')
    ->set ( $index->sql_index_only_doc_id_type );

  return ( $self );
}

sub MAJOR_NUMBER {
  1;
}

sub decl_pos {
  return undef;
}

sub make_id {
  my ( $self, $struct ) = @_;

  if ( $self->{_IO_derive_from} ) {
    # get the id from some element or method
    my $id = $struct->{doc}->auto_dispatch ( $self->{_IO_derive_from},
                                              @{$self->{_IO_derive_args}} );
    die "Derived_file got no value from its derive_from: " .
      $self->{_IO_derive_from} . "\n"  if  ! $id;
    return ( $id, '' );
  }
  return ( 'COMMA_DB_SEQUENCE_SET', '' );
}

# mostly, we can just call index->update to do the work, here. the one
# complication is that we'll need to do a bit of cleanup -- setting
# the doc's storage_info fields correctly -- if this is a first-time
# write (or copy). we depend on the index insert code to generate a
# doc_id, but the insert code doesn't know enough to set all of the
# storage_info fields.
sub write {
  my ( $self, $store, $location, $id, $block, $doc ) = @_;
  my $need_to_set_sinfo = ( $id eq 'COMMA_DB_SEQUENCE_SET' );
  my $index = $doc->def()->get_index ( $self->{_index_name} );
  # index -- if the index operation returns undef, throw a store error
  # (eventually)
  $index->update ( $doc ) or die $@;
  if ( $need_to_set_sinfo ) {
    $id = $doc->doc_id();
    my $stype = $store->doctype();
    my $sname = $store->name();
    my $key = XML::Comma::Storage::Util->_concat_key ( $stype, $sname, $id );
    my $locked = XML::Comma->lock_singlet()->lock ( $key );
    $doc->set_storage_info ( $store, undef, undef, $key );
  };
}

sub location_from_id {
  my ( $self, $store, $id, $location ) = @_;
  return $id;
}

# FIX: recognize a special field in the index (perhaps 'comma_block')
# that is a pre-stored doc-block, which we will use in preference to
# calling _build_block_from_fields if possible.
sub read {
  my  ( $self, $store, $location, $id ) = @_;
  my $index = XML::Comma::Def->read ( name => $self->{_doctype} )
    ->get_index ( $self->{_index_name} );
  my $single = $index->single ( where_clause => "doc_id='$id'" )
    || die ( "doc with id '$id' not found in index\n" );

  return $self->_build_block_from_fields ( $index, $single );
}

sub _build_block_from_fields {
  my ( $self, $index, $single ) = @_;
  my $string = '<' . $self->{_doctype} . '>';
  foreach my $field ( $index->elements('field') ) {
    my $fname = $field->name();
    $string .= "<$fname>" . $single->$fname . "</$fname>";
  }
  $string .= '</' . $self->{_doctype} . '>';
  return $string;
}

sub erase {
  my ( $self, $location, $doc ) = @_;
  my $index = $doc->def()->get_index ( $self->{_index_name} );
  $index->delete ( $doc );
}

sub next_location {
  die
    "Docs stored Index_Only cannot be iterated across, use indexing operations instead\n";
}

sub first_location {
  die
    "Docs stored Index_Only cannot be iterated across, use indexing operations instead\n";
}

sub last_location {
  die
    "Docs stored Index_Only cannot be iterated across, use indexing operations instead\n";
}

sub write_blob {
  die "Docs stored Index_Only cannot store blobs\n";
}

sub read_blob {
  die "Docs stored Index_Only cannot store blobs\n";
}

sub copy_to_blob {
  die "Docs stored Index_Only cannot store blobs\n";
}

sub erase_blob {
  die "Docs stored Index_Only cannot store blobs\n";
}


sub touch {
  die "FIX: implement touch for Index_Only storage\n";
}

sub last_modified {
  die "FIX: implement last-modified for Index_Only storage\n";
}

1;
