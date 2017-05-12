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

package XML::Comma::Storage::Location::Abstract_file;

use strict;
use File::Spec;
use File::Copy;
use XML::Comma::Util qw( dbg );

# _extension :
# _decl_pos  :
#
# children should use an _init method (which this classes "new" method
# calls, to process arguments and set up their states. the _init
# method should return a list of methods that are "exported" by the
# child class, which new() will add to its own list of exports.
#
# exports: extension()
#
# provides: MAJOR_NUMBER(), decl_pos(), read and write methods, next_
# methods, blob methods and touch/last_modified.
#


sub new {
  my ( $class, %arg ) = @_; my $self = {}; bless ( $self, $class );
  $self->{_extension} = (defined $arg{extension}) ? $arg{extension} : '.comma';
  $self->{_decl_pos} = $arg{decl_pos};
  return ( $self, 'extension', $self->_init(%arg) );
}

sub MAJOR_NUMBER {
  1;
}

sub decl_pos {
  return $_[0]->{_decl_pos}
}

sub write {
  my ( $self, $store, $location, $id, $block ) = @_;
  XML::Comma::Storage::FileUtil->write_file ( $location,
                                              $block,
                                              $store->file_permissions() );
}

sub read {
  my ( $self, $store, $location, $id ) = @_;
  return XML::Comma::Storage::FileUtil->read_file($location);
}

sub erase {
  my ( $self, $location ) = @_;
  unlink $location;
}

sub next_location {
  my ( $self, $store, $location, $direction ) = @_;
  my ( $volume, $directories, $file ) = File::Spec->splitpath ( $location );
  return XML::Comma::Storage::FileUtil->next_in_dir_path
    ( $store->base_directory(),
      $directories,
      $file,
      $self->{_extension},
      $direction );
}

sub first_location {
  my ( $self, $store ) = @_;
  return XML::Comma::Storage::FileUtil->first_or_last_down_dir_path
    ( $store->base_directory(),
      $self->{_extension} );
}

sub last_location {
  my ( $self, $store ) = @_;
  return XML::Comma::Storage::FileUtil->first_or_last_down_dir_path
    ( $store->base_directory(),
      $self->{_extension},
      1 );
}

sub write_blob {
  my ( $self, $store, $store_location, $store_id, $blob,
       $content, $new_location ) = @_;
  my $blocation;
  if ( $new_location ) {
    $blocation = XML::Comma::Storage::FileUtil->create_randnamed_file
      ( (File::Spec->splitpath($store_location))[1],
        $store_id . '-',
        $blob->get_extension(),
        $store->file_permissions() );
  } else {
    $blocation = $blob->get_location() ||
      XML::Comma::Storage::FileUtil->create_randnamed_file
          ( (File::Spec->splitpath($store_location))[1],
            $store_id . '-',
            $blob->get_extension(),
            $store->file_permissions() );
  }
  XML::Comma::Storage::FileUtil->write_file ( $blocation,
                                              $content,
                                              $store->file_permissions() );
  return $blocation;
}

sub read_blob {
  my ( $self, $store, $blob ) = @_;
  return XML::Comma::Storage::FileUtil->read_file ( $blob->get_location() );
}

sub copy_to_blob {
  my ( $self, $store, $store_location, $store_id, $blob, 
       $from_filename, $to_filename ) = @_;
  my $blocation = $to_filename ||
    XML::Comma::Storage::FileUtil->create_randnamed_file
        ( (File::Spec->splitpath($store_location))[1],
          $store_id . '-',
          #$blob->def()->element('extension')->get(),
          $blob->get_extension(),
          $store->file_permissions() );
  copy ( $from_filename, $blocation ) ||
    die "could not copy to blob file '$from_filename': $!\n";
  return $blocation;
}

sub erase_blob {
  my ( $self, $store, $blob, $blob_location ) = @_;
  # dbg 'trying to unlink', $blob_location || $blob || '<none>';
  if ( $blob_location ) {
    unlink $blob_location;
  } else {
    unlink $blob->get_location();
  }
  # dbg 'done unlinking';
}

sub touch {
  my ( $self, $store, $location ) = @_;
  my $now = time;
  utime $now, $now, ( $location );
  return $now;
}

sub last_modified {
  my ( $self, $store, $location ) = @_;
  return (stat($location))[9];
}


##

sub extension {
  return $_[0]->{_extension};
}

1;


