##
#
#    Copyright 2004-2005, AllAfrica Global Media
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

package XML::Comma::Configable;

####
# dispatch config routines for initialization
####
sub _config_dispatcher {
  my $self = shift();
  foreach my $el ( $self->elements() ) {
    my $method_name = '_config__' . $el->tag();
    if ( $self->can($method_name) ) {
      $self->$method_name($el);
    }
  }
  if ( $self->can('_config__DONE__') ) {
    $self->_config__DONE__();
  }
}

1;
