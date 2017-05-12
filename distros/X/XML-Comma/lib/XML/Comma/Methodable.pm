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

package XML::Comma::Methodable;

## a class that wants to be Methodable *MUST* also be Configable

use strict;


sub _config__method {
  my ( $self, $el ) = @_;
  my $code_ref = eval $el->element('code')->get();
  die XML::Comma::Log->err ( 'METHOD_PARSE_ERR', $@, undef, 
                             'in "' . $el->element('name')->get . '"' )
    if  $@;
  $self->add_method ( $el->element('name')->get(),
                      $el->element('code')->get() );
}

sub add_method {
  my ( $self, $name, $method ) = @_;
  $self->{_Methodable_methods} ||= {};
  my $code_ref;
  if ( ref($method) eq 'CODE' ) {
    $code_ref = $method;
  } else {
    $code_ref = eval $method;
    die "error while defining method '$name': $@"  if  $@;
  }
  $self->{_Methodable_methods}->{$name} = $code_ref;
  return $method;
}

sub get_method {
  my ( $self, $name ) = @_;
  return $self->{_Methodable_methods}->{$name};
}

sub method_names {
  return keys %{$_[0]->{_Methodable_methods}};
}

1;
