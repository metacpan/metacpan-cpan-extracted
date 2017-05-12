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

package XML::Comma::Storage::Location::Derived_GMT_3layer_dir;

use XML::Comma::Storage::Location::GMT_3layer_dir;
@ISA = ( 'XML::Comma::Storage::Location::GMT_3layer_dir' );

use strict;
use XML::Comma::Util qw( dbg );
use File::Spec;

# _Dd_derive_from            : required

sub new {
  my ( $class, %args ) = @_;
  my $self = {}; bless ( $self, $class );
  $self->{_Dd_derive_from} = $args{derive_from} ||
    die "Derived_GMT_3layer_dir Location needs a 'derive_from' argument\n";
  $self->{_decl_pos} = $args{decl_pos};
  return ( $self );
}

sub make_id {
  my ( $self, $struct ) = @_;
  # check for overflow
  if ( $struct->{overflow} ) {
    die "Derived_GMT_3layer_dir full\n";
  }
  # get the id from some element or method
  my $string = $struct->{doc}->auto_dispatch ( $self->{_Dd_derive_from} );
  die "Derived_GMT_3layer_dir got no value from its derive_from: " .
    $self->{_Dd_derive_from} . "\n"  if  ! $string;
  # pull apart string into YYYY MM DD (FIX: accept more string formats)
  unless ( $string =~ /(\d{4})(\d{2})(\d{2})/ ) {
    die "Derived_GMT_3layer_dir didn't understand '$string'\n";
  }
  return ( "$1$2$3",                         # id piece
           File::Spec->catdir($1, $2, $3),   # location piece
         );
}


1;

