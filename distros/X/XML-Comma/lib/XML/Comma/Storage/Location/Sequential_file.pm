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

package XML::Comma::Storage::Location::Sequential_file;

@ISA = ( 'XML::Comma::Storage::Location::Abstract_file' );

use strict;
use Math::BaseCalc;
use XML::Comma::Storage::Location::Abstract_file;
use XML::Comma::Util qw( dbg );

# _Sf_basecalc    : Math::BaseCalc object for formatting next id
# _Sf_max         :
# _Sf_width       :
# _Sf_first_digit :

sub _init {
  my ( $self, %arg ) = @_;
  $self->{_Sf_basecalc} =
    Math::BaseCalc->new ( digits => $arg{digits} || [0..9] );
  $self->{_Sf_max} = $arg{max} || 9999;
  my $formatted_max = $self->{_Sf_basecalc}->to_base ( $self->{_Sf_max} );
  $self->{_Sf_width} = length ( $formatted_max );
  ( $self->{_Sf_first_digit} ) = $self->{_Sf_basecalc}->digits();
  return ( 'extension' );
}

sub make_id {
  my ( $self, $struct ) = @_; 
  my $location = File::Spec->catdir ( @{$struct->{locs}} );
  my $next_id = XML::Comma::Storage::FileUtil->next_sequential_id
    ( $struct->{store},
      $location,
      $self->{_extension},
      $self->{_Sf_max} );
  return undef  if  ! defined $next_id;
  $next_id = sprintf ( '% *s', $self->{_Sf_width},
                       $self->{_Sf_basecalc}->to_base($next_id) );
  my $fd = $self->{_Sf_first_digit};
  $next_id =~ s| |$fd|g; 
  return ( join('',@{$struct->{ids}},$next_id),
           File::Spec->catfile($location, $next_id.$self->{_extension}) );
}

sub location_from_id {
  my ( $self, $store, $id, $location ) = @_; 
  die "bad id\n" if ( length($id) != $self->{_Sf_width} );
  return ( '', File::Spec->catfile($location,$id.$self->{_extension}) );
}

sub id_from_location {
  my ( $self, $store, $id, $location ) = @_; 
  die "bad location\n" unless($location);
  $location =~ /^(.*)${ \( $self->{_extension} ) }$/ ||
    die "bad location\n";
  return ( $id . sprintf("%0*s", $self->{_Sf_width}, $1), '' );
}


1;

