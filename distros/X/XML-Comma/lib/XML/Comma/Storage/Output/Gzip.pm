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

package XML::Comma::Storage::Output::Gzip;

use XML::Comma::Util qw( dbg );
use Compress::Zlib;

sub new {
  my ( $class, %args ) = @_;
  my $self = {}; bless ( $self, $class );
  return $self;
}

sub output {
  # dbg 'output', 'gzip';
  return Compress::Zlib::memGzip ( $_[1] );
}

sub input {
  # dbg 'input', 'gzip';
  return Compress::Zlib::memGunzip ( $_[1] );
}


1;


