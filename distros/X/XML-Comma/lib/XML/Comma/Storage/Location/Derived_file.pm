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

package XML::Comma::Storage::Location::Derived_file;

@ISA = ( 'XML::Comma::Storage::Location::Abstract_file' );

use strict;
use XML::Comma::Storage::Location::Abstract_file;
use XML::Comma::Storage::FileUtil;
use XML::Comma::Util qw( dbg );

# _Df_derive_from   : required
# _Df_derive_args   : <here for experimental purposes, not publicly documented>
#
# _Df_balanced : { end => 'head' or 'tail',
#              :   length => numerical argument, length of "balance" string }


sub _init {
  my ( $self, %arg ) = @_;
  # derive from
  $self->{_Df_derive_from} = $arg{derive_from} ||
    die "Derived_file Location needs a 'derive_from'\n";
  # head or tail balanced?
  if ( $arg{head_balanced} and $arg{tail_balanced} ) {
    die "Derived_file can only be head_ OR tail_balanced\n";
  } elsif ( $arg{head_balanced} ) {
    $self->{_Df_balanced} = { end => 'head', length => $arg{head_balanced} };
  } elsif ( $arg{tail_balanced} ) {
    $self->{_Df_balanced} = { end => 'tail', length => $arg{tail_balanced} };
  }
  # derive_args (experimental)
  $self->{_Df_derive_args} = $arg{derive_args} || [];
  # return
  return ( 'extension' );
}

sub make_id {
  my ( $self, $struct ) = @_;
  # get the id from some element or method
  my $string = $struct->{doc}->auto_dispatch ( $self->{_Df_derive_from},
                                               @{$self->{_Df_derive_args}} );
  die "Derived_file got no value from its derive_from: " .
    $self->{_Df_derive_from} . "\n"  if  ! $string;
  # balance directory
  my $balance_dir = $self->_get_balance_directory ( $string );
  push @{$struct->{locs}}, $balance_dir  if  $balance_dir;
  # make location string
  my $location = File::Spec->canonpath
                 (File::Spec->catfile (@{$struct->{locs}},
                                       $string.$self->{_extension}) );
  # now we need to make sure the directory (which we've been passed in
  # pieces, and perhaps have just added a _balance piece to)
  # exists. even if we haven't added a _balance piece, the directory
  # might not exist (in some of the other Location modules the
  # next_sequential_id stuff does this directory creation for us)
  my ( undef, $directory ) = File::Spec->splitpath ( $location );
  XML::Comma::Storage::FileUtil->make_directory ( $struct->{store},
                                                  $directory );
  # make matching id
  my $id = join ( '',@{$struct->{ids}},$string );
  return ( $id, $location );
}

sub location_from_id {
  my ( $self, $store, $id, $location ) = @_;
  die "bad id\n"  if  ! $id;
  my $balance_dir = $self->_get_balance_directory ( $id );
  if ( $balance_dir ) {
    return
      ( '',
        File::Spec->canonpath
        (File::Spec->catfile($location,$balance_dir,$id.$self->{_extension})) );
  } else {
    return ( '',
             File::Spec->canonpath
             (File::Spec->catfile($location,$id.$self->{_extension})) );
  }
}

sub id_from_location {
  my ( $self, $store, $id, $location ) = @_;
  die "bad location\n"  if  ! $location;
  $location =~ /^(.*)${ \( $self->{_extension} ) }$/ ||
    die "bad location\n";
  my $body = $1;
  if ( $self->{_Df_balanced} ) {
    # assumption: directory path separator is one character wide
    # FIX: shouldn't this have logic for *both* head and tail balancing?
    $body = substr ( $body, $self->{_Df_balanced}->{length}+1 );
  }
  return ( $id . $body, '' );
}

sub _get_balance_directory {
  my ( $self, $string ) = @_;
  # if head or tail balanced, substr to get the balance directory name
  # and add that to the locs pieces
  my $dir_string;
  if ( $self->{_Df_balanced} ) {
    if ( $self->{_Df_balanced}->{end} eq 'head' ) {
      $dir_string = substr ( $string, 0, $self->{_Df_balanced}->{length} );
    } else {
      $dir_string = substr ( $string, -1 * $self->{_Df_balanced}->{length} );
    }
    $dir_string = sprintf("%0*s", $self->{_Df_balanced}->{length}, $dir_string);
  }
  return $dir_string;
}

1;




