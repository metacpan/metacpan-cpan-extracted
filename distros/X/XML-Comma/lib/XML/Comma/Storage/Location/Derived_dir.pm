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

package XML::Comma::Storage::Location::Derived_dir;

use strict;
use XML::Comma::Util qw( dbg );
use File::Spec;

# _Dd_derive_from            : required
# _Dd_width                  : required
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
$self->{_Dd_derive_from} = $args{derive_from} ||
    die "Derived_dir Location needs a 'derive_from' argument\n";
  $self->{_Dd_width} = $args{max} ||
    die "Derived_dir Location needs a 'max' argument\n";
  $self->{_decl_pos} = $args{decl_pos};
  return ( $self );
}

sub make_id {
  my ( $self, $struct ) = @_;
  # get the id from some element or method
  my $string = $struct->{doc}->auto_dispatch ( $self->{_Dd_derive_from} );
  die "Derived_dir got no value from its derive_from: " .
    $self->{_Dd_derive_from} . "\n"  if  ! $string;
  # pad/trim to the correct length
  my $next_id = substr ( sprintf("%0*s", $self->{_Dd_width}, $string),
                         0, $self->{_Dd_width} );
  # return the new pieces
  return ( $next_id, # id piece
           $next_id  # location piece
         );
}

sub location_from_id {
  my ( $self, $store, $id, $location ) = @_;
  my $substring = substr ( $id, 0, $self->{_Dd_width} );
  if ( length($substring) != $self->{_Dd_width} ) {
    die "bad id\n";
  }
  return ( substr($id,$self->{_Dd_width} ),
           File::Spec->catdir($location,$substring) );
}

sub id_from_location {
  my ( $self, $store, $id, $location ) = @_;
  my @directories = File::Spec->splitdir($location);
  if ( ! @directories ) {
    die "bad location\n";
  }
  return ( $id . sprintf("%0*s", $self->{_Dd_width}, shift(@directories)),
           File::Spec->catdir(@directories) );
}


1;

