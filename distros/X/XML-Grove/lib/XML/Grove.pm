#
# Copyright (C) 1998 Ken MacLeod
# XML::Grove is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Grove.pm,v 1.15 1999/08/17 15:01:28 kmacleod Exp $
#

use strict;
use 5.005;
use UNIVERSAL;
use Data::Grove;

package XML::Grove;
use vars qw{$VERSION @ISA};

$VERSION = '0.46alpha';

@ISA = qw{Data::Grove};

package XML::Grove::Document;
use vars qw{@ISA $type_name};
@ISA = qw{XML::Grove};

$type_name = 'document';

# Override methods that may be loaded from Data::Grove::Parent.  In
# XML::Grove, `root' and `rootpath' refer to the root _element_ of the
# grove, not the document that contains it.

# Note: this routine specifically sets $value and does last instead of
# returning $child immediately because there is a bug in Perl 5.005 that
# causes the returned value to disappear
sub root {
    my $self = shift;

    if (@_) {
	return $self->{Contents} = [ shift ];
    } else {
	my $value = undef;

	foreach my $child (@{$self->{Contents}}) {
	    if ($child->isa('XML::Grove::Element')) {
		$value = $child;
		last;
	    }
	}

	return $value;
    }
}

sub rootpath {
    return;
}

package XML::Grove::Element;
use vars qw{ @ISA $type_name };
@ISA = qw{XML::Grove};
$type_name = 'element';

package XML::Grove::PI;
use vars qw{ @ISA $type_name };
@ISA = qw{XML::Grove};
$type_name = 'pi';

package XML::Grove::Entity::External;
use vars qw{ @ISA $type_name };
@ISA = qw{XML::Grove};
$type_name = 'external_entity';

package XML::Grove::Entity::SubDoc;
use vars qw{ @ISA $type_name };
@ISA = qw{XML::Grove};
$type_name = 'subdoc_entity';

package XML::Grove::Entity::SGML;
use vars qw{ @ISA $type_name };
@ISA = qw{XML::Grove};
$type_name = 'sgml_entity';

package XML::Grove::Entity;
use vars qw{ @ISA $type_name };
@ISA = qw{XML::Grove};
$type_name = 'entity';

package XML::Grove::Notation;
use vars qw{ @ISA $type_name };
@ISA = qw{XML::Grove};
$type_name = 'notation';

package XML::Grove::Comment;
use vars qw{ @ISA $type_name };
@ISA = qw{XML::Grove};
$type_name = 'comment';

package XML::Grove::SubDoc;
use vars qw{ @ISA $type_name };
@ISA = qw{XML::Grove};
$type_name = 'subdoc';

package XML::Grove::Characters;
use vars qw{ @ISA $type_name };
@ISA = qw{XML::Grove};
$type_name = 'characters';

package XML::Grove::CData;
use vars qw{ @ISA $type_name };
@ISA = qw{XML::Grove};
$type_name = 'cdata';

package XML::Grove::ElementDecl;
use vars qw{ @ISA $type_name };
@ISA = qw{XML::Grove};
$type_name = 'element_decl';

package XML::Grove::AttListDecl;
use vars qw{ @ISA $type_name };
@ISA = qw{XML::Grove};
$type_name = 'attlist_decl';

1;

__END__

=head1 NAME

XML::Grove - Perl-style XML objects

=head1 SYNOPSIS

 use XML::Grove;

 # Basic parsing and grove building
 use XML::Grove::Builder;
 use XML::Parser::PerlSAX;
 $grove_builder = XML::Grove::Builder->new;
 $parser = XML::Parser::PerlSAX->new ( Handler => $grove_builder );
 $document = $parser->parse ( Source => { SystemId => 'filename' } );

 # Creating new objects
 $document = XML::Grove::Document->new ( Contents => [ ] );
 $element = XML::Grove::Element->new ( Name => 'tag',
                                       Attributes => { },
				       Contents => [ ] );

 # Accessing XML objects
 $tag_name = $element->{Name};
 $contents = $element->{Contents};
 $parent = $element->{Parent};
 $characters->{Data} = 'XML is fun!';

=head1 DESCRIPTION

XML::Grove is a tree-based object model for accessing the information
set of parsed or stored XML, HTML, or SGML instances.  XML::Grove
objects are Perl hashes and arrays where you access the properties of
the objects using normal Perl syntax:

  $text = $characters->{Data};

=head2 How To Create a Grove

There are several ways for groves to come into being, they can be read
from a file or string using a parser and a grove builder, they can be
created by your Perl code using the `C<new()>' methods of
XML::Grove::Objects, or databases or other sources can act as groves.

The most common way to build groves is using a parser and a grove
builder.  The parser is the package that reads the characters of an
XML file, recognizes the XML syntax, and produces ``events'' reporting
when elements (tags), text (characters), processing instructions, and
other sequences occur.  A grove builder receives (``consumes'' or
``handles'') these events and builds XML::Grove objects.  The last
thing the parser does is return the XML::Grove::Document object that
the grove builder created, with all of it's elements and character
data.

The most common parser and grove builder are XML::Parser::PerlSAX (in
libxml-perl) and XML::Grove::Builder.  To build a grove, create the
grove builder first:

  $grove_builder = XML::Grove::Builder->new;

Then create the parser, passing it the grove builder as it's handler:

  $parser = XML::Parser::PerlSAX->new ( Handler => $grove_builder );

This associates the grove builder with the parser so that every time
you parse a document with this parser it will return an
XML::Grove::Document object.  To parse a file, use the `C<Source>'
parameter to the `C<parse()>' method containing a `C<SystemId>'
parameter (URL or path) of the file you want to parse:

  $document = $parser->parse ( Source => { SystemId => 'kjv.xml' } );

To parse a string held in a Perl variable, use the `C<Source>'
parameter containing a `C<String>' parameter:

  $document = $parser->parse ( Source => { String => $xml_text } );

The following are all parsers that work with XML::Grove::Builder:

  XML::Parser::PerlSAX (in libxml-perl, uses XML::Parser)
  XML::ESISParser      (in libxml-perl, uses James Clark's `nsgmls')
  XML::SAX2Perl        (in libxml-perl, translates SAX 1.0 to PerlSAX)

Most parsers supply more properties than the standard information set
below and XML::Grove will make available all the properties given by
the parser, refer to the parser documentation to find out what
additional properties it may provide.

Although there are not any available yet (August 1999), PerlSAX filters
can be used to process the output of a parser before it is passed to
XML::Grove::Builder.  XML::Grove::PerlSAX can be used to provide input
to PerlSAX filters or other PerlSAX handlers.

=head2 Using Groves

The properties provided by parsers are available directly using Perl's
normal syntax for accessing hashes and arrays.  For example, to get
the name of an element:

  $element_name = $element->{Name};

By convention, all properties provided by parsers are in mixed case.
`C<Parent>' properties are available using the
`C<Data::Grove::Parent>' module.

The following is the minimal set of objects and their properties that
you are likely to get from all parsers:

=head2 XML::Grove::Document

The Document object is parent of the root element of the parsed XML
document.

=over 12

=item Contents

An array containing the root element.

=back

A document's `Contents' may also contain processing instructions,
comments, and whitespace.

Some parsers provide information about the document type, the XML
declaration, or notations and entities.  Check the parser
documentation for property names.

=head2 XML::Grove::Element

The Element object represents elements from the XML source.

=over 12

=item Parent

The parent object of this element.

=item Name

A string, the element type name of this element

=item Attributes

A hash of strings or arrays

=item Contents

An array of elements, characters, processing instructions, etc.

=back

In a purely minimal grove, the attributes of an element will be plain
text (Perl scalars).  Some parsers provide access to notations and
entities in attributes, in which case the attribute may contain an
array.

=head2 XML::Grove::Characters

The Characters object represents text from the XML source.

=over 12

=item Parent

The parent object of this characters object

=item Data

A string, the characters

=back

=head2 XML::Grove::PI

The PI object represents processing instructions from the XML source.

=over 12

=item Parent

The parent object of this PI object.

=item Target

A string, the processing instruction target.

=item Data

A string, the processing instruction data, or undef if none was supplied.

=back

In addition to the minimal set of objects above, XML::Grove knows
about and parsers may provide the following objects.  Refer to the
parser documentation for descriptions of the properties of these
objects.

  XML::Grove::
  ::Entity::External  External entity reference
  ::Entity::SubDoc    External SubDoc reference (SGML)
  ::Entity::SGML      External SGML reference (SGML)
  ::Entity            Entity reference
  ::Notation          Notation declaration
  ::Comment           <!-- A Comment -->
  ::SubDoc            A parsed subdocument (SGML)
  ::CData             A CDATA marked section
  ::ElementDecl       An element declaration from the DTD
  ::AttListDecl       An element's attribute declaration, from the DTD

=head1 METHODS

XML::Grove by itself only provides one method, new(), for creating new
XML::Grove objects.  There are Data::Grove and XML::Grove extension
modules that give additional methods for working with XML::Grove
objects and new extensions can be created as needed.

=over 4

=item $obj = XML::Grove::OBJECT->new( [PROPERTIES] )

`C<new>' creates a new XML::Grove object with the type I<OBJECT>, and
with the initial I<PROPERTIES>.  I<PROPERTIES> may be given as either
a list of key-value pairs, a hash, or an XML::Grove object to copy.
I<OBJECT> may be any of the objects listed above.

=back

This is a list of available extensions and the methods they provide
(as of Feb 1999).  Refer to their module documentation for more
information on how to use them.

  XML::Grove::AsString
    as_string       return portions of groves as a string
    attr_as_string  return an element's attribute as a string

  XML::Grove::AsCanonXML
    as_canon_xml    return XML text in canonical XML format

  XML::Grove::PerlSAX
    parse           emulate a PerlSAX parser using the grove objects

  Data::Grove::Parent
    root            return the root element of a grove
    rootpath        return an array of all objects between the root
                    element and this object, inclusive

    Data::Grove::Parent also adds `C<Parent>' and `C<Raw>' properties
    to grove objects.

  Data::Grove::Visitor
    accept          call back a subroutine using an object type name
    accept_name     call back using an element or tag name
    children_accept for each child in Contents, call back a sub
    children_accept_name  same, but using tag names
    attr_accept     call back for the objects in attributes

  XML::Grove::IDs
    get_ids         return a list of all ID attributes in grove

  XML::Grove::Path
    at_path         $el->at_path('/html/body/ul/li[4]')

  XML::Grove::Sub
    filter          run a sub against all the objects in the grove

=head1 WRITING EXTENSIONS

The class `C<XML::Grove>' is the superclass of all classes in the
XML::Grove module.  `C<XML::Grove>' is a subclass of `C<Data::Grove>'.

If you create an extension and you want to add a method to I<all>
XML::Grove objects, then create that method in the XML::Grove
package.  Many extensions only need to add methods to
XML::Grove::Document and/or XML::Grove::Element.

When you create an extension you should definitly provide a way to
invoke your module using objects from your package too.  For example,
XML::Grove::AsString's `C<as_string()>' method can also be called
using an XML::Grove::AsString object:

  $writer= new XML::Grove::AsString;
  $string = $writer->as_string ( $xml_object );

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), XML::Grove(3)

Extensible Markup Language (XML) <http://www.w3c.org/XML>

=cut
