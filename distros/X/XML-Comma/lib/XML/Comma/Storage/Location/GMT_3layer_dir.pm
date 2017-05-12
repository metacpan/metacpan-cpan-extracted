##
#
#    Copyright 2005, AllAfrica Global Media
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

package XML::Comma::Storage::Location::GMT_3layer_dir;

use strict;
use XML::Comma::Util qw( dbg );
use File::Spec;


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
  $self->{_decl_pos} = $args{decl_pos};
  return ( $self );
}

sub make_id {
  my ( $self, $struct ) = @_;
  if ( $struct->{overflow} ) {
    die "GMT_3layer_dir full\n";
  }
  my ( $year, $month, $day ) = XML::Comma::Storage::Util->gmt_yyyy_mm_dd();
  return ( "$year$month$day",                         # id piece
           File::Spec->catdir($year, $month, $day),   # location piece
         );
}

sub location_from_id {
  my ( $self, $store, $id, $location ) = @_;
  my $substring = substr ( $id, 0, 8 );
  if ( length($substring) != 8 ) {
    die "bad id, too short\n";
  }
  $substring =~ /(\d{4})(\d{2})(\d{2})/;
  return ( substr($id,8),
           File::Spec->catdir($location,$1,$2,$3) );
}

sub id_from_location {
  my ( $self, $store, $id, $location ) = @_;
  my @directories = File::Spec->splitdir($location);
  if ( scalar(@directories) < 4 ) {
    die "bad location, too short\n";
  }
  return ( $id . shift(@directories).shift(@directories).shift(@directories),
           File::Spec->catfile(@directories) );
}


1;

