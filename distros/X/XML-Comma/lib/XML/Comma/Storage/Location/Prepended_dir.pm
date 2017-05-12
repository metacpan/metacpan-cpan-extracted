##
#
#    Copyright 2003, AllAfrica Global Media
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

package XML::Comma::Storage::Location::Prepended_dir;

use strict;
use XML::Comma::Util qw( dbg );
use File::Spec;

# _Pd_derive_from
# _Pd_sep
# _decl_pos                  :

sub MAJOR_NUMBER {
  400;
}

sub decl_pos {
  return $_[0]->{_decl_pos};
}


sub new {
  my ( $class, %args ) = @_;
  my $self = {}; bless ( $self, $class );
  $self->{_Pd_derive_from} = $args{derive_from};
  $self->{_Pd_sep} = $args{sep} || '.';
  $self->{_decl_pos} = $args{decl_pos};
  return ( $self );
}

sub make_id {
  my ( $self, $struct ) = @_;
  unless ( $self->{_Pd_derive_from} ) {
    die "Prepended_dir with no 'derive from' is read only\n";
  }

  # get the id from some element or method
  my $string = $struct->{doc}->auto_dispatch ( $self->{_Pd_derive_from} );
  die "Prepended_dir got nothing from its derive_from '" .
    $self->{_Pd_derive_from} . "'\n"  unless  $string;
  # return the new pieces
  return (
          $string . $self->{_Pd_sep}, # id piece
          $string                     # location piece
         );
}

sub location_from_id {
  my ( $self, $store, $id, $location ) = @_;
  my $mark = index ( $id, $self->{_Pd_sep} );
  if ( $mark == -1 ) {
    die "Prepended_dir could not find sep string '" . $self->{_Pd_sep} .
      "' in id fragment '$id'\n";
  }
  my $location_fragment = substr ( $id, 0, $mark );
  my $shortened_id = substr ( $id, $mark+1 );

  return ( $shortened_id,
           File::Spec->catdir($location,$location_fragment) );
}

sub id_from_location {
  my ( $self, $store, $id, $location ) = @_;
  my @directories = File::Spec->splitdir($location);
  if ( ! @directories ) {
    die "bad location\n";
  }
  return ( $id . shift(@directories) . $self->{_Pd_sep},
           File::Spec->catdir(@directories) );
}


1;

