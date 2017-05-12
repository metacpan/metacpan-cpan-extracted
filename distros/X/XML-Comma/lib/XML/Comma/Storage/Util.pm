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

package XML::Comma::Storage::Util;

use strict;

sub concat_key {
  my ( $class, %arg ) = @_;
  return "$arg{type}|$arg{store}|$arg{id}";
}

#faster version of concat_key, with args in order instead of hash
sub _concat_key {
  my ( $class, $type, $store, $id ) = @_;
  return "$type|$store|$id";
}

# return (type, storage-name, id);
sub split_key {
  return split ( /\|/, $_[1] );
}

sub gmt_yyyy_mm_dd {
  my $time = $_[1] || time;
#  my $time = time;
  my ($day, $month, $year) = (gmtime($time))[3..5];
  # increment and/or trim as necessary
  $year+=1900; $month++;
  $month = substr ( "00$month", -2 ); $day = substr ( "00$day", -2 );
  return ( $year, $month, $day, $time );
}

1;

