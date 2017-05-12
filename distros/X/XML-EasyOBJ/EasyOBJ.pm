
=head1 NAME

XML::EasyOBJ - Easy XML object navigation

=head1 VERSION

Version 1.12

=head1 SYNOPSIS

 # open exisiting file
 my $doc = new XML::EasyOBJ('my_xml_document.xml');
 my $doc = new XML::EasyOBJ(-type => 'file', -param => 'my_xml_document.xml');

 # create object from XML string
 my $doc = new XML::EasyOBJ(-type => 'string', -param => $xml_source);

 # create new file
 my $doc = new XML::EasyOBJ(-type => 'new', -param => 'root_tag');
 
 # read from document
 my $text = $doc->some_element($index)->getString;
 my $attr = $doc->some_element($index)->getAttr('foo');
 my $element = $doc->some_element($index);
 my @elements = $doc->some_element;

 # first "some_element" element
 my $elements = $doc->some_element;
 # list of "some_element" elements
 my @elements = $doc->some_element;

 # write to document
 $doc->an_element->setString('some string')
 $doc->an_element->addString('some string')
 $doc->an_element->setAttr('attrname', 'val')
 $doc->an_element->setAttr('attr1' => 'val', 'attr2' => 'val2')

 # access elements with non-name chars and the underlying DOM
 my $element = $doc->getElement('foo-bar')->getElement('bar-none');
 my $dom = $doc->foobar->getDomObj;

 # get elements without specifying the element name
 my @elements = $doc->getElement();
 my $sixth_element = $doc->getElement('', 5);

 # remove elements/attrs
 $doc->remElement('tagname', $index);
 $doc->tag_name->remAttr($attr);

 # remap builtin methods
 $doc->remapMethod('getString', 's');
 my $text = $doc->some_element->s;


=head1 DESCRIPTION

I wrote XML::EasyOBJ a couple of years ago because it seemed to me
that the DOM wasn't very "perlish" and the DOM is difficult for us
mere mortals that don't use it on a regular basis.  As I only need
to process XML on an occasionally I wanted an easy way to do what
I needed to do without having to refer back to DOM documentation
each time.

A quick fact list about XML::EasyOBJ:

 * Runs on top of XML::DOM
 * Allows access to the DOM as needed
 * Simple routines to reading and writing elements/attributes

=head1 REQUIREMENTS

XML::EasyOBJ uses XML::DOM.  XML::DOM is available from CPAN (www.cpan.org).

=head1 METHODS

Below is a description of the methods avialable.

=cut

package XML::EasyOBJ;

use strict;
use XML::DOM;
use vars qw/$VERSION/;

$VERSION = '1.12';

=head2 new

You can create a new object from an XML file, a string of XML, or
a new document.  The constructor takes a set of key value pairs as
follows:

=item -type

The type is either "file", "string" or "new".  "file" will create
the object from a file source, "string" will create the object from
a string of XML code, and "new" will create a new document object.

=item -param

This value depends on the -type that is passed to the constructor.
If the -type is "file" this will be the filename to open and parse.
If -type is "string", this is a string of XML code.  If -type is
"new", this is the name of the root element.

Creating an object from an XML file:

 my $doc = new XML::EasyOBJ(-type => 'file', -param => 'my_xml_document.xml');

Creating an object from a string containing the XML source:

 my $doc = new XML::EasyOBJ(-type => 'string', -param => $xml_source);

Creating a new XML document by passing the root tag name:

 my $doc = new XML::EasyOBJ(-type => 'new', -param => 'root_tag');

=item -expref

Passing a value of 1 will force the expansion of references when
grabbing string data from the XML file.  The default value is 0,
not to expand references.


Obtionally you may also pass the filename to open as the first
argument instead of passing the -type and -param parameters.
This is backwards compatable with early version of XML::EasyOBJ
which did not handle -type and -param parameters.

 my $doc = new XML::EasyOBJ('my_xml_document.xml');

=cut

sub new {
    my $class = shift;

    # container for DOM object
    my $doc = '';

    # expand references flag. true to expand.
    my $expref = 0;

    # if there are an odd number of parameters, take the first
    # argument as a filename.
    if ( scalar(@_) % 2 ) {
	my $file = shift;
	my $parser = new XML::DOM::Parser;
	$doc = $parser->parsefile( $file ) || return;
    }
    # if there are an even number of arguments, treat them as
    # hash name/value pairs.
    else {
	my %args = @_;

	# check for "expand references" flag, and set $expref
	$expref = 1 if ( exists $args{-expref} and $args{-expref} == 1 );

	# create DOM from file, param is filename
	if ( $args{-type} eq 'file' ) {
	    my $parser = new XML::DOM::Parser;
	    $doc = $parser->parsefile( $args{-param} ) || return;
	}
	# create a new DOM object, param is root element name
	elsif ( $args{-type} eq 'new' ) {
	    $doc = new XML::DOM::Document();
	    $doc->appendChild( $doc->createElement( $args{-param} ) );
	}
	# create DOM from string
	elsif ( $args{-type} eq 'string' ) {
	    my $parser = new XML::DOM::Parser;
	    $doc = $parser->parse( $args{-param} ) || return;
	}
	else {
	    return;
	}
    }

    # set method mappings, may be changed by remapMethod method
    my %map = ( getString   => 'getString',
		setString   => 'setString',
		addString   => 'addString',
		getAttr     => 'getAttr',
		setAttr     => 'setAttr',
		remAttr     => 'remAttr',
		remElement  => 'remElement',
		getElement  => 'getElement',
		getDomObj   => 'getDomObj',
		remapMethod => 'remapMethod',
		getTagName  => 'getTagName',
	      );

    return bless( { 'map' => \%map,
		    'doc' => $doc,
		    'ptr' => $doc->getDocumentElement(),
		    'expref' => $expref,
		  }, 'XML::EasyOBJ::Object' );
}

package XML::EasyOBJ::Object;

use strict;
use XML::DOM;
use vars qw/%SUBLIST %INTSUBLIST $AUTOLOAD/;

$AUTOLOAD = '';
%SUBLIST = ();
%INTSUBLIST = ();

sub DESTROY {
    local $^W = 0;
    my $self = $_[0];
    $_[0] = '';
    unless ( $_[0] ) {
	$_[0] = $self;
	$AUTOLOAD = 'DESTROY';
	return AUTOLOAD( @_ );
    }
}

sub AUTOLOAD {
    my $funcname = $AUTOLOAD || 'AUTOLOAD';
    $funcname =~ s/^XML::EasyOBJ::Object:://;
    $AUTOLOAD = '';

    if ( exists $_[0]->{map}->{$funcname} ) {
	return &{$SUBLIST{$_[0]->{map}->{$funcname}}}( @_ );
    }

    my $self = shift;
    my $index = shift;
    my @nodes = ();

    die "Fatal error: lost pointer!" unless ( exists $self->{ptr} );

    for my $kid ( $self->{ptr}->getChildNodes ) {
	if ( ( $kid->getNodeType == ELEMENT_NODE ) && ( $kid->getTagName eq $funcname ) ) {
	    push @nodes, bless( 
			       {	map => $self->{map}, 
					doc => $self->{doc}, 
					ptr => $kid,
					expref => $self->{expref},
			       }, 'XML::EasyOBJ::Object' );
	}
    }

    if ( wantarray ) {
	return @nodes;
    }
    else {
	if ( defined $index ) {
	    unless ( defined $nodes[$index] ) {
		for ( my $i = scalar(@nodes); $i <= $index; $i++ ) {
		    $nodes[$i] = bless(
				       { 	map => $self->{map}, 
						doc => $self->{doc}, 
						ptr => &{$INTSUBLIST{'makeNewNode'}}( $self, $funcname ),
						expref => $self->{expref},
				       }, 'XML::EasyOBJ::Object' )
		} 
	    }
	    return $nodes[$index];
	}
	else {
	    return bless( 
			 { 	map => $self->{map}, 
				doc => $self->{doc}, 
				ptr => &{$INTSUBLIST{'makeNewNode'}}( $self, $funcname ),
				expref => $self->{expref},
			 }, 'XML::EasyOBJ::Object' ) unless ( defined $nodes[0] );
	    return $nodes[0];
	}
    }
}

=head2 makeNewNode( NEW_TAG )

Append a new element node to the current node. Takes the tag name
as the parameter and returns the created node as a convienence.

 my $p_element = $doc->body->makeNewNode('p');

=cut

$INTSUBLIST{'makeNewNode'} =
  sub {
      my $self = shift;
      my $element_name = shift;
      return $self->{ptr}->appendChild( $self->{doc}->createElement($element_name) );
  };

=head2 remapMethod( CUR_METHOD, NEW_METHOD )

Allows you to change the name of any of the object methods. You
might want to do this for convienience or to avoid a naming
collision with an element in the document.

Two parameters need to be passed; the current name of the method
and the new name. Returns 1 on a successful mapping and undef
on failure. A failure can result if you don't pass two parameters
if if the "copy from" method name does not exist.

 $doc->remapMethod('getString', 's');
 $doc->s();

After remapping you must use the new name if you with to remap
the method again.  You can call the remapMethod method from
any place in the XML tree and it will always change the method
globally.

In the following example $val1 and $val2 are equal:

 $doc->some_element->another_element->('getString', 's');
 my $val1 = $doc->s();
 $doc->remapMethod('s', 'getString');
 my $val2 = $doc->getString();

=cut

$SUBLIST{remapMethod} =
  sub {
      my $self = shift;
      my ( $from, $to ) = @_;

      die "Fatal error: lost the pointer!" unless ( exists $self->{ptr} );

      return unless ( ( $from ) && ( $to ) );
      return unless ( exists $self->{map}->{$from} );

      my $tmp = $self->{map}->{$from};
      delete $self->{map}->{$from};
      $self->{map}->{$to} = $tmp;
      return 1;
  };

=head2 getString( )

Recursively extracts text from the current node and all children
element nodes. Returns the extracted text as a single scalar value.
Expands entities based on if the -expref flag was supplied during
object creation.

=cut

$SUBLIST{getString} =
  sub {
      my $self = shift;
      die "Fatal error: lost the pointer!" unless ( exists $self->{ptr} );
      my $string = &{$INTSUBLIST{extractText}}( $self->{ptr} );
      return ( $self->{expref} ) ? $self->{doc}->expandEntityRefs($string) : $string;
  };

=head2 extractText( )

Same as getString() but does not check the -expref flag.  Included for
compatability with inital version of interface.

=cut

$INTSUBLIST{extractText} =
  sub {
      my $n = shift;
      my $text;

      if ( $n->getNodeType == TEXT_NODE ) {
	  $text = $n->toString;
      }
      elsif ( $n->getNodeType == ELEMENT_NODE ) {
	  foreach my $c ( $n->getChildNodes ) {
	      $text .= &{$INTSUBLIST{extractText}}( $c );
	  }
      }
      return $text;
  };

=head2 setString( STRING )

Sets the text value of the specified element. This is done by
first removing all text node children of the current element
and then appending the supplied text as a new child element.

Take this XML fragment and code for example:

<p>This elment has <b>text</b> and <i>child</i> elements</p>

 $doc->p->setString('This is the new text');

This will change the fragment to this:

<p><b>text</b><i>child</i>This is the new text</p>

Because the <b> and <i> tags are not text nodes they are left
unchanged, and the new text is added at the end of the specified
element.

If you need more specific control on the change you should
either use the getDomObj() method and use the DOM methods
directly or remove all of the child nodes and rebuild the
<p> element from scratch.  Also see the addString() method.

=cut

$SUBLIST{setString} = 
  sub {
      my $self = shift;
      my $text = shift;

      die "Fatal error: lost the pointer!" unless ( exists $self->{ptr} );

      foreach my $n ( $self->{ptr}->getChildNodes ) {
	  if ( $n->getNodeType == TEXT_NODE ) {
	      $self->{ptr}->removeChild( $n );
	  }
      }

      $self->{ptr}->appendChild( $self->{doc}->createTextNode( $text ) );
      return &{$INTSUBLIST{extractText}}( $self->{ptr} );
  };

=head2 addString( STRING )

Adds to the the text value of the specified element. This
is done by appending the supplied text as a new child element.

Take this XML fragment and code for example:

<p>This elment has <b>text</b></p>

 $doc->p->addString(' and elements');

This will change the fragment to this:

<p>This elment has <b>text</b> and elements</p>

=cut

$SUBLIST{addString} =
  sub {
      my $self = shift;
      my $text = shift;

      die "Fatal error: lost the pointer!" unless ( exists $self->{ptr} );

      $self->{ptr}->appendChild( $self->{doc}->createTextNode( $text ) );
      return &{$INTSUBLIST{extractText}}( $self->{ptr} );
  };

=head2 getAttr( ATTR_NAME )

Returns the value of the named attribute.

 my $val = $doc->body->img->getAttr('src');

=cut

$SUBLIST{getAttr} = 
  sub {
      my $self = shift;
      my $attr = shift;

      die "Fatal error: lost the pointer!" unless( exists $self->{ptr} );
      if ( $self->{ptr}->getNodeType == ELEMENT_NODE ) {
	  return $self->{ptr}->getAttribute($attr);
      }
      return '';
  };

=head2 getTagName( )

Returns the tag name of the specified element. This method is
useful when you are enumerating child elements and do not
know their element names.

 foreach my $element ( $doc->getElement() ) {
    print $element->getTagName();
 }

=cut

$SUBLIST{getTagName} = 
  sub {
      my $self = shift;
      
      die "Fatal error: lost the pointer!" unless( exists $self->{ptr} );
      if ( $self->{ptr}->getNodeType == ELEMENT_NODE ) {
	  return $self->{ptr}->getTagName;
      }
      return '';
  };

=head2 setAttr( ATTR_NAME, ATTR_VALUE, [ATTR_NAME, ATTR_VALUE]... )

For each name/value pair passed the attribute name and value will
be set for the specified element.

=cut

$SUBLIST{setAttr} =
  sub {
      my $self = shift;
      my %attr = @_;

      die "Fatal error: lost the pointer!" unless( exists $self->{ptr} );
      if ( $self->{ptr}->getNodeType == ELEMENT_NODE ) {
	  if ( scalar(keys %attr) == 1 ) {
	      for ( keys %attr ) {
		  return $self->{ptr}->setAttribute($_, $attr{$_});
	      }
	  }
	  else {
	      for ( keys %attr ) {
		  $self->{ptr}->setAttribute($_, $attr{$_});
	      }
	      return 1;
	  }
      }
      return '';
  };

=head2 remAttr( ATTR_NAME )

Removes the specified attribute from the current element.

=cut

$SUBLIST{remAttr} = 
  sub {
      my $self = shift;
      my $attr = shift;
      
      die "Fatal error: lost the pointer!" unless( exists $self->{ptr} );
      if ( $self->{ptr}->getNodeType == ELEMENT_NODE ) {
	  if ( $self->{ptr}->getAttributes->getNamedItem( $attr ) ) {
	      $self->{ptr}->getAttributes->removeNamedItem( $attr );
	      return 1;
	  }
      }
      return 0;
  };

=head2 remElement( TAG_NAME, INDEX )

Removes a child element of the current element. The name of the
child element and the index must be supplied.  An index of 0
will remove the first occurance of the named element, 1 the second,
2 the third, etc.

=cut

$SUBLIST{remElement} = 
  sub {
      my $self = shift;
      my $name = shift;
      my $index = shift;
      
      my $node = ( $index ) ? $self->$name($index) : $self->$name();
      $self->{ptr}->removeChild( $node->{ptr} );
  };

=head2 getElement( TAG_NAME, INDEX )

Returns the node from the tag name and index. If no index is
given the first child with that name is returned. Use this
method when you have element names that include characters that
are not legal as a perl method name.  For example:

 <foo> <!-- root element -->
  <bar>
   <foo-bar>test</foo-bar>
  </bar>
 </foo>

 # "foo-bar" is not a legal method name
 print $doc->bar->getElement('foo-bar')->getString();

=cut

$SUBLIST{getElement} = 
  sub {
      my $self = shift;
      my $funcname = shift;
      my $index = shift;
      my @nodes = ();

      die "Fatal error: lost pointer!" unless ( exists $self->{ptr} );

      foreach my $kid ( $self->{ptr}->getChildNodes ) {
	  if ( $funcname ) {
	      if ( ( $kid->getNodeType == ELEMENT_NODE ) && ( $kid->getTagName eq $funcname ) ) {
		  push @nodes, bless( 
				     {	map => $self->{map}, 
					doc => $self->{doc}, 
					ptr => $kid,
					expref => $self->{expref},
				     }, 'XML::EasyOBJ::Object' );
	      }
	  }
	  else {
	      if ( $kid->getNodeType == ELEMENT_NODE ) {
		  push @nodes, bless( 
				     {	map => $self->{map}, 
					doc => $self->{doc}, 
					ptr => $kid,
					expref => $self->{expref},
				     }, 'XML::EasyOBJ::Object' );
	      }
	  }
      }
      
      if ( wantarray ) {
	  return @nodes;
      }
      else {
	  $index = 0 unless ( defined $index );

	  if ( defined $nodes[$index] ) {
	      return $nodes[$index];
	  }
	  else {
	      # fail if no tag name given
	      return undef unless ( $funcname );

	      for ( my $i = scalar(@nodes); $i <= $index; $i++ ) {
		  $nodes[$i] = bless(
				     { 	map => $self->{map}, 
					doc => $self->{doc}, 
					ptr => &{$INTSUBLIST{'makeNewNode'}}( $self, $funcname ),
					expref => $self->{expref},
				     }, 'XML::EasyOBJ::Object' )
	      }

	      return $nodes[$index];
	  }
      }
  };

=head1 getDomObj( )

Returns the DOM object associated with the current node. This
is useful when you need fine access via the DOM to perform
a specific function.

=cut

$SUBLIST{getDomObj} = 
  sub {
      my $self = shift;
      return $self->{ptr};
  };

1;

=head1 BEGINNER QUICK START GUIDE

=head2 Introduction

You too can write XML applications, just as long as you understand
the basics of XML (elements and attributes). You can learn to write
your first program that can read data from an XML file in a mere
10 minutes.

=head2 Assumptions

It is assumed that you are familiar with the structure of the document that
you are reading.  Next, you must know the basics of perl lists, loops, and
how to call a function.  You must also have an XML document to read.

Simple eh?

=head2 Loading the XML document

 use XML::EasyOBJ;
 my $doc = new XML::EasyOBJ('my_xml_document.xml') || die "Can't make object";

Replace the string "my_xml_document.xml" with the name of your XML document.
If the document is in another directory you will need to specify the path
to it as well.

The variable $doc is an object, and represents our root XML element in the document.

=head2 Reading text with getString

Each element becomes an object. So lets assume that the XML page looks like
this:

 <table>
  <record>
   <rec2 foo="bar">
    <field1>field1a</field1>
    <field2>field2b</field2>
    <field3>field3c</field3>
   </rec2>
   <rec2 foo="baz">
    <field1>field1d</field1>
    <field2>field2e</field2>
    <field3>field3f</field3>
   </rec2>
  </record>
 </table>

As mentioned in he last step, the $doc object is the root
element of the XML page. In this case the root element is the "table"
element.

To read the text of any field is as easy as navigating the XML elements.
For example, lets say that we want to retrieve the text "field2e". This
text is in the "field2" element of the SECOND "rec2" element, which is
in the FIRST "record" element.

So the code to print that value it looks like this:

 print $doc->record(0)->rec2(1)->field2->getString;

The "getString" method returns the text within an element.

We can also break it down like this:

 # grab the FIRST "record" element (index starts at 0)
 my $record = $doc->record(0);
 
 # grab the SECOND "rec2" element within $record
 my $rec2 = $record->rec2(1);
 
 # grab the "field2" element from $rec2
 # NOTE: If you don't specify an index, the first item 
 #       is returned and in this case there is only 1.
 my $field2 = $rec2->field2;

 # print the text
 print $field2->getString;

=head2 Reading XML attributes with getAttr

Looking at the example in the previous step, can you guess what
this code will print?

 print $doc->record(0)->rec2(0)->getAttr('foo');
 print $doc->record(0)->rec2(1)->getAttr('foo');

If you couldn't guess, they will print out the value of the "foo"
attribute of the first and second rec2 elements. 

=head2 Looping through elements

Lets take our example in the previous step where we printed the
attribute values and rewrite it to use a loop. This will allow
it to print all of the "foo" attributes no matter how many "rec2"
elements we have.

 foreach my $rec2 ( $doc->record(0)->rec2 ) {
   print $rec2->getAttr('foo');
 }

When we call $doc->record(0)->rec2 this way (i.e. in list context), 
the module will return a list of "rec2" elements.

=head2 That's it!

You are now an XML programmer! *start rejoicing now*

=head1 PROGRAMMING NOTES

When creating a new instance of XML::EasyOBJ it will return an
object reference on success, or undef on failure. Besides that,
ALL methods will always return a value. This means that if you
specify an element that does not exist, it will still return an
object reference (and create that element automagically). This 
is just another way to lower the bar, and make this module easier 
to use.

You will run into problems if you have XML tags which are named
after perl's special subroutine names (i.e. "DESTROY", "AUTOLOAD"), 
or if they are named after subroutines used in the module 
( "getString", "getAttr", etc ). You can get around this by using
the getElement() method of using the remapMethod() method which can
be used on every object method (except AUTOLOAD and DESTROY).

=head1 AUTHOR/COPYRIGHT

Copyright (C) 2000-2002 Robert Hanson <rhanson@blast.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

XML::DOM

=cut



