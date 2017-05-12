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

package XML::Comma::Storage::Location::Read_only_file;

@ISA = ( 'XML::Comma::Storage::Location::Abstract_file' );

use strict;
use XML::Comma::Storage::Location::Abstract_file;
use XML::Comma::Util qw( dbg );
use XML::Comma;

sub new {
  my ( $class, %args ) = @_;
  my $self = {}; bless ( $self, $class );
  $self->{_Sf_extension} = defined $args{extension} ? 
    $args{extension} : '.comma';
  return ( $self, 'extension' );
}

sub make_id {
  die "Read_only_file cannot be used to write, only to read.\n";
}

sub location_from_id {
  my ( $self, $store, $id, $location ) = @_;
  return ( '',
           File::Spec->catfile($location,$id.$self->{_Sf_extension}) );
}

sub id_from_location {
  my ( $self, $store, $id, $location ) = @_;
  if ( ! $location ) {
    die "bad location\n";
  }
  $location =~ /^(.*)${ \( $self->{_Sf_extension} ) }$/ ||
    die "bad location\n";
  return ( $id . $1,
           '' );
}

sub write {
  die "Read_only_file is not allowed to write\n";
}

##

sub extension {
  return $_[0]->{_Sf_extension};
}

1;




