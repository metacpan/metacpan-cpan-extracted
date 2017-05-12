##
#
#    Copyright 2002, AllAfrica Global Media
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
#    http://xml-comma.org, or read the tutorial included with the
#    XML::Comma distribution at docs/guide.html
#
##

package XML::Comma::Storage::Location::SequentialCheck_file;

@ISA = ( 'XML::Comma::Storage::Location::Abstract_file' );

use strict;
use XML::Comma::Storage::Location::Abstract_file;
use XML::Comma::Util qw( dbg );

# _Sf_max       :
# _Sf_width     :

our $Checks = {
  mod11 => sub {
#   MOD11 check digit.
    my $n = shift;
    my $s = 0;
    my $c;
    while ($n) {
      $s += (chop $n) * ($c++ % 6 + 2);
      }
    (11 - ($s % 11)) % 10;
    },

  luhn => sub {
#   The standard credit card check digit. Also called MOD10.
    my $n = shift;
    my $s = 0;
    my $c = 2;
    my $t;
    while ($n) {
      $t = (chop $n) * $c;
      $s += ($t>9)?((chop $t)+$t):$t;
      $c ^= 0b11;
      }
    (10 - ($s % 10)) % 10;
    },

  mod110 => sub {
#   MOD11 check digit, modified for a particular client.
    my $n = shift;
    my $s = 0;
    my $c;
    while ($n) {
      $s += (chop $n) * ($c++ % 6 + 2);
      }
    $s = 11 - ($s % 11);
    ($s > 9)?0:$s;
    }
  };

 
sub _init {
  my ( $self, %arg ) = @_;
  $arg{check} ||= 'mod110';
  defined $Checks->{$arg{check}} 
    or die "Uknown check algorythim";
  $self->{_Sf_check} = $Checks->{$arg{check}};
  $self->{_Sf_max} = $arg{max} || 999;
  $self->{_Sf_width} = length ( $self->{_Sf_max} ) + 1;
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

  $next_id = sprintf ( "%0*s", $self->{_Sf_width}-1, $next_id )
    . &{$self->{_Sf_check}}( join('',@{$struct->{ids}},$next_id));

  return ( join('',@{$struct->{ids}},$next_id),
           File::Spec->catfile($location, $next_id.$self->{_extension}) );
}

sub location_from_id {
  my ( $self, $store, $id, $location ) = @_;
  if ( length($id) != $self->{_Sf_width} ) {
    die "bad id\n";
  }
  return ( '',
           File::Spec->catfile($location,$id.$self->{_extension}) );
}

sub id_from_location {
  my ( $self, $store, $id, $location ) = @_;
  if ( ! $location ) {
    die "bad location\n";
  }
  $location =~ /^(.*)${ \( $self->{_extension} ) }$/ ||
    die "bad location\n";
  return ( $id . sprintf("%0*s", $self->{_Sf_width}, $1),
           '' );
}


1;
