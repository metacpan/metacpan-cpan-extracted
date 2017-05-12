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

package XML::Comma::Storage::Location::Sequential_dir;

use strict;
use Math::BaseCalc;
use XML::Comma::Util qw( dbg );
use File::Spec;

# _Sd_basecalc    : Math::BaseCalc object for formatting next id
# _Sd_max         :
# _Sd_width       :
# _Sd_first_digit :
# _decl_pos       :

sub MAJOR_NUMBER {
  400;
}

sub decl_pos {
  return $_[0]->{_decl_pos};
}


sub new {
  my ( $class, %arg ) = @_;
  my $self = {}; bless ( $self, $class );
  $self->{_Sd_basecalc} =
    Math::BaseCalc->new ( digits => $arg{digits} || [0..9] );
  $self->{_Sd_max} = $arg{max} || 9999;
  #dbg 'max', $self->{_Sd_max};
  my $formatted_max = $self->{_Sd_basecalc}->to_base ( $self->{_Sd_max} );
  $self->{_Sd_width} = length ( $formatted_max );
  $self->{_decl_pos} = $arg{decl_pos};
  ( $self->{_Sd_first_digit} ) = $self->{_Sd_basecalc}->digits();
  return ( $self );
}

sub make_id {
  my ( $self, $struct ) = @_;
  my $next_id;
  my @iargs = ( $struct->{store},
                File::Spec->catdir ( @{$struct->{locs}} ),
                '',
                $self->{_Sd_max} );
  if ( $struct->{overflow} ) {
    $next_id = XML::Comma::Storage::FileUtil->next_sequential_id ( @iargs );
  } else {
    $next_id = XML::Comma::Storage::FileUtil->current_sequential_id ( @iargs );
    if ( ! defined $next_id ) {
      # this is the first storage here, we need to call next_sequential_id
      $next_id = XML::Comma::Storage::FileUtil->next_sequential_id ( @iargs )
        or die "unspecified error in Sequential_dir\n";
    }
  }
  return  undef  if   ! defined $next_id;
  #dbg 'next_id', $next_id;
  $next_id = sprintf ( "% *s", $self->{_Sd_width},
                       $self->{_Sd_basecalc}->to_base($next_id) );
  my $fd = $self->{_Sd_first_digit};
  $next_id =~ s| |$fd|g;
  return ( $next_id, # id piece
           $next_id  # location piece
         );
}

sub location_from_id {
  my ( $self, $store, $id, $location ) = @_;
  my $substring = substr ( $id, 0, $self->{_Sd_width} );
  if ( length($substring) != $self->{_Sd_width} ) {
    die "bad id\n";
  }
  return ( substr($id,$self->{_Sd_width} ),
           File::Spec->catdir($location,$substring) );
}

sub id_from_location {
  my ( $self, $store, $id, $location ) = @_;
  my @directories = File::Spec->splitdir($location);
  if ( ! @directories ) {
    die "bad location\n";
  }
  return ( $id . sprintf("%0*s", $self->{_Sd_width}, shift(@directories)),
           File::Spec->catdir(@directories) );
}


1;

