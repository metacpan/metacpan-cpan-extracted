=head1 NAME

XML::EasySQL::XMLobj - Fork of Robert Hanson's killer XML::EasyOBJ
module, which offers Easy XML object navigation

=head1 VERSION

Version 1.2

=head1 SYNOPSIS

XML::EasySQL::XMLobj is a fork of Robert Hanson's XML::EasyOBJ module.
The goal of the fork was to simplify inheritance issues. However, easy
inheritance comes at a cost: class method names can no longer be
dynamically renamed. If inheritance isn't needed and you desire
the dynamic method renaming feature, I suggest you download Hanson's
original XML::EasyOBJ module from CPAN.

NOTE: The rest of the documentation for this module was written by
Robert Hanson

-Curtis Lee Fulton

 # open exisiting file
 my $doc = new XML::EasySQL::XMLobj({type => 'file', param => 'my_xml_document.xml'});

 # create object from XML string
 my $doc = new XML::EasySQL::XMLobj({type => 'string', -param => $xml_source});

 # create new file
 my $doc = new XML::EasySQL::XMLobj({type => 'new', param => 'root_tag'});

 # read from document
 my $text = $doc->root->some_element($index)->getString;
 my $attr = $doc->root->some_element($index)->getAttr('foo');
 my $element = $doc->root->some_element($index);
 my @elements = $doc->root->some_element;

 # first "some_element" element
 my $elements = $doc->root->some_element;
 # list of "some_element" elements
 my @elements = $doc->root->some_element;

 # write to document
 $doc->root->an_element->setString('some string')
 $doc->root->an_element->addString('some string')
 $doc->root->an_element->setAttr('attrname', 'val')
 $doc->root->an_element->setAttr('attr1' => 'val', 'attr2' => 'val2')

 # access elements with non-name chars and the underlying DOM
 my $element = $doc->root->getElement('foo-bar')->getElement('bar-none');
 my $dom = $doc->root->foobar->getDomObj;

 # get elements without specifying the element name
 my @elements = $doc->root->getElement();
 my $sixth_element = $doc->root->getElement('', 5);

 # remove elements/attrs
 $doc->root->remElement('tagname', $index);
 $doc->root->tag_name->remAttr($attr);

=head1 DESCRIPTION

I wrote XML::EasyOBJ a couple of years ago because it seemed to me
that the DOM wasn't very "perlish" and the DOM is difficult for us
mere mortals that don't use it on a regular basis.  As I only need
to process XML on an occasionally I wanted an easy way to do what
I needed to do without having to refer back to DOM documentation
each time.

A quick fact list about XML::EasySQL::XMLobj:

 * Runs on top of XML::DOM
 * Allows access to the DOM as needed
 * Simple routines to reading and writing elements/attributes

=head1 REQUIREMENTS

XML::EasySQL::XMLobj uses XML::DOM.  XML::DOM is available from CPAN (www.cpan.org).

=head1 METHODS

Below is a description of the class constructor. See XML::EasySQL::XMLobj::Node for the method documentation.

=cut

package XML::EasySQL::XMLobj;

use XML::DOM;
use strict;

use vars qw/$VERSION/;
$VERSION = '1.2';

=head2 new

You can create a new object from an XML file, a string of XML, or
a new document.  The constructor takes an anon hash with the following
keys:

=over

=item type

The type is either "file", "string" or "new".  "file" will create
the object from a file source, "string" will create the object from
a string of XML code, and "new" will create a new document object.

=item param

This value depends on the -type that is passed to the constructor.
If the -type is "file" this will be the filename to open and parse.
If -type is "string", this is a string of XML code.  If -type is
"new", this is the name of the root element.

=item class_constructor

If you've made a derived class from XML::EasySQL::XMLnode, specify the class
name here. It defaults to XML::EasySQL::XMLobj::Node.

If you're using constructor_class, any additional keys will be passed on to
the XML::EasySQL::XMLobj::Node derived class.

Creating an object from an XML file:

 my $doc = new XML::EasySQL::XMLobj({type => 'file', param => 'my_xml_document.xml'});

Creating an object from a string containing the XML source:

 my $doc = new XML::EasySQL::XMLobj({type => 'string', param => $xml_source});

Creating a new XML document by passing the root tag name:

 my $doc = new XML::EasySQL::XMLobj({type => 'new', param => 'root_tag'});

=back

=cut

sub new {
	my $proto = shift;
	my $params = shift;
	my $class = ref($proto) || $proto;
	my $self = {};

	# container for DOM object
	my $doc = undef;

	# create DOM from file, param is filename
	if ( $params->{type} eq 'file' ) {
		my $parser = new XML::DOM::Parser;
		$doc = $parser->parsefile( $params->{param} ) || return undef;
	}

	# create a new DOM object, param is root element name
	elsif ( $params->{type} eq 'new' ) {
		$doc = new XML::DOM::Document();
		$doc->appendChild( $doc->createElement($params->{param}) );
	}

	# create DOM from string
	elsif ( $params->{type} eq 'string' ) {
	    my $parser = new XML::DOM::Parser;
	    $doc = $parser->parse( $params->{param} ) || return undef;
	} else {
	    die "bad arguments for __PACKAGE__ constructor\n";
	}

	if(!defined $doc) {
	    die "problem creating XML::DOM document. Check your __PACKAGE__ constructor arguments\n";
	}

	$self->{doc} = $doc;
	$self->{ptr} = $doc->getDocumentElement();
	$self->{constructor_class} = $params->{constructor_class};

	my %constructor_params_copy = %{$params};
	delete $constructor_params_copy{type};
	delete $constructor_params_copy{param};
	delete $constructor_params_copy{constructor_class};

	$self->{constructor_params} = \%constructor_params_copy;

	$self->{root} = undef;

	bless $self, $class;
}

=head2 root

The root XML::EasySQL::XMLobj::Node object.

=cut

sub root {
	my $self = shift;
	if(!ref $self->{root}) {
		$self->_root();
	}
	return $self->{root};
}

sub _root {
	my $self = shift;
	my $doc = $self->{doc};
	my $ptr = $self->{ptr};

	if(defined $self->{constructor_class}) {
		my %constructor_params_copy = %{$self->{constructor_params}};
		$constructor_params_copy{doc} = $doc;
		$constructor_params_copy{ptr} = $ptr;
		$constructor_params_copy{constructor_params} = $self->{constructor_params};
		$self->{root} = $self->{constructor_class}->new(\%constructor_params_copy);
	} else {
		use XML::EasySQL::XMLobj::Node;
		$self->{root} = XML::EasySQL::XMLobj::Node->new({doc=>$doc, ptr=>$ptr});
	}
}

=head2 constructorParams

Returns a hash ref of args. If you're using a derived node class,
you can change the args the node constructor gets by modifying this hash.

=cut

sub constructorParams {
	my $self = shift;
	return $self->{constructor_params};
}

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

 use XML::EasySQL::XMLobj;
 my $doc = new XML::EasySQL::XMLobj({type=>'file', param=>'my_xml_document.xml'});

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

 print $doc->root->record(0)->rec2(1)->field2->getString;

The "getString" method returns the text within an element.

We can also break it down like this:

 # grab the FIRST "record" element (index starts at 0)
 my $record = $doc->root->record(0);

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

 print $doc->root->record(0)->rec2(0)->getAttr('foo');
 print $doc->root->record(0)->rec2(1)->getAttr('foo');

If you couldn't guess, they will print out the value of the "foo"
attribute of the first and second rec2 elements. 

=head2 Looping through elements

Lets take our example in the previous step where we printed the
attribute values and rewrite it to use a loop. This will allow
it to print all of the "foo" attributes no matter how many "rec2"
elements we have.

 foreach my $rec2 ( $doc->root->record(0)->rec2 ) {
   print $rec2->getAttr('foo');
 }

When we call $doc->record(0)->rec2 this way (i.e. in list context), 
the module will return a list of "rec2" elements.

=head2 That's it!

You are now an XML programmer! *start rejoicing now*

=head1 PROGRAMMING NOTES

Both XML::EasySQL::XMLobj and XML::EasySQL::XMLobj::Node can be
used as base classes.

When creating a new instance of XML::EasySQL::XMLobj it will return an
object reference on success, or die on failure. Besides that,
ALL methods will always return a value. This means that if you
specify an element that does not exist, it will still return an
object reference (and create that element automagically). This 
is just another way to lower the bar, and make this module easier 
to use.

You will run into problems if you have XML tags which are named
after perl's special subroutine names (i.e. "DESTROY", "AUTOLOAD"), 
or if they are named after subroutines used in the module 
( "getString", "getAttr", etc ). You can get around this by using
the getElement() method. If you need to rename the methods dynamically,
(except AUTOLOAD and DESTROY), try Hanson's original from CPAN.

=head1 AUTHOR/COPYRIGHT

Copyright (C) 2000-2002 Robert Hanson <rhanson@blast.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Forked by Curtis Lee Fulton 2-29-04.

=head1 SEE ALSO

XML::DOM

XML::EasySQL::XMLobj::Node

=cut



