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

package XML::Comma::Util::DefModule;
use XML::Comma;

use strict;
use warnings;

my %loaded;

sub load_def {
  my $class = shift;
  if ( $loaded{ $class } ) {
    return $loaded{ $class };
  }
  my $def = XML::Comma::Def->new( block => $class->_def_string() );

  # cache based on pre and post decorator class names
  $loaded{ $class } = $def;
  $loaded{ $def   } = $def;
  return $def;
}

sub _def_string {
  my $class = shift;
  {
    no strict 'refs';
    my $fh = *{"$class\::DATA"};
    local $/ = undef;
    return <$fh>;
  }
}

1;

=pod

=head1 NAME

XML::Comma::Util::DefModule - Abstract parent for modules that define
a Def in a __DATA__ block.

=head1 DESCRIPTION

This module provides an easy way to define a Def inside a
module. Children of XML::Comma::Util::DefModule inherit two methods:

  load_def
  new

The Def is created from a string found in the DATA section of the
module. The load_def() method should be called by the inheriting
class, in order to load the Def into Comma's weltenshmatzel. The
default new() method simply returns a new Doc of the Def's type, and
can be used as-is or overridden. A complete, basic inheritor might
look like this:

  package Example::Frobulator;

  use strict;
  use warnings;

  use base 'XML::Comma::Util::DefModule';
  __PACKAGE__->load_def;

  1;

  __DATA__

  <DocumentDefinition>
    <name>Example_Frobulator</name>
    <class><module>Example::Frobulator</module></class>

    <element><name>frobuvalue</name></element>
  </DocumentDefinition>

You can access the def from this object in a variety of
ways, all of which are equivalent:

  $def = XML::Comma::Def->Example_Frobulator;
  $def = Example::Frobulator->load_def();
  $def = Example::Frobulator->def();
  $def = Example::Frobulator->new(%args)->def();

NOTE: when overriding def(), it is easy to make a circular
reference which cannot be garbage collected, leading to
various unintuitive problems. NEVER DO THIS:

  sub def {
    my $def = XML::Comma::Def->read( name => "Example_Frobulator" );
    #do some stuff with $def
    return $def;
  }

The safe way to do this is to use DefModule's def() method, which
has magic to take care of proper memory management for you:

  sub def {
    my $def = __PACKAGE__->def;
    #do some stuff with $def
    return $def;
  }

As an added bonus, def() implemented this way will work when called
from a class or instance, like the default.

=cut
