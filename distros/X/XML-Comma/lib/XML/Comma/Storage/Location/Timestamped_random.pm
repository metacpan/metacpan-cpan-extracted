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

package XML::Comma::Storage::Location::Timestamped_random;

@ISA = ( 'XML::Comma::Storage::Location::Abstract_file' );

use strict;
use XML::Comma::Storage::Location::Abstract_file;
use XML::Comma::Storage::FileUtil;
use XML::Comma::Util qw( random_an_string 
                         urlsafe_ascify_32bits urlsafe_deascify_32bits );

# _Tr_gmt_balance : optional

sub _init {
  my ( $self, %arg ) = @_;
  $self->{_Tr_gmt_balance} = $arg{gmt_balance};
  return ( 'extension' );
}

sub make_id {
  my ( $self, $struct ) = @_;
  my $rand_string = random_an_string(10);
  my ( $year, $month, $day, $time )=XML::Comma::Storage::Util->gmt_yyyy_mm_dd();
  my $b64_time = urlsafe_ascify_32bits ( $time );
  my $balance_dir = '';
  if ( $self->{_Tr_gmt_balance} ) {
    $balance_dir = "$year$month$day";
  }
  push @{$struct->{locs}}, $balance_dir  if  $balance_dir;
  # we need to make sure the directory (which we've been passed in
  # pieces, and perhaps have just added a _balance piece to)
  # exists. even if we haven't added a _balance piece, the directory
  # might not exist (in some of the other Location modules the
  # next_sequential_id stuff does this directory creation for us)
  my $directory = File::Spec->catdir ( @{$struct->{locs}} );
  XML::Comma::Storage::FileUtil->make_directory ( $struct->{store},
                                                  $directory );
  # make and return the location and id strings
  my $location = File::Spec->catfile
    ( $directory,
      $b64_time.$rand_string.$self->{_extension} );
  my $id = join ( '',@{$struct->{ids}},$b64_time,$rand_string );
  return ( $id, $location );
}

sub location_from_id {
  my ( $self, $store, $id, $location ) = @_;
  die "bad id\n"  if  ! $id;
  my $balance_dir = $self->_get_balance_directory ( $id );
  if ( $balance_dir ) {
    return
      ( '',
        File::Spec->catfile($location,$balance_dir,$id.$self->{_extension}) );
  } else {
    return ( '',
             File::Spec->catfile($location,$id.$self->{_extension}) );
  }
}

sub id_from_location {
  my ( $self, $store, $id, $location ) = @_;
  die "bad location\n"  if  ! $location;
  #print "id: $id -- loc: $location\n";
  $location =~ /^(.*)${ \( $self->{_extension} ) }$/ ||
    die "bad location\n";
  my $body = $1;
  #print "b: $body\n";
  if ( $self->{_Tr_gmt_balance} ) {
    # assumption: directory path separator is one character wide
    $body = substr ( $body, 8+1 );
  }
  #print $id . $body . "\n";
  return ( $id . $body, '' );
}

sub _get_balance_directory {
  my ( $self, $id_string ) = @_;
  return ''  unless  $self->{_Tr_gmt_balance};
  my $time = urlsafe_deascify_32bits( substr($id_string, 0, 6) );
  my ( $year, $month, $day )=XML::Comma::Storage::Util->gmt_yyyy_mm_dd($time);
  return "$year$month$day";
}

1;




