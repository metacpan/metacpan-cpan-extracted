package XML::Mini;
use strict;
$^W = 1;

use vars qw (
	     $AutoEscapeEntities
	     $AutoSetParent
	     $AvoidLoops
	     $CaseSensitive
	     $Debug
	     $IgnoreWhitespaces
	     $NoWhiteSpaces
	     $CheckXMLBeforeParsing
	     $DieOnBadXML
	     $VERSION
	     $IgnoreDeepRecursionWarnings
	     );

$VERSION = '1.38';

$AvoidLoops = 0;
$AutoEscapeEntities = 1;
$Debug = 0;
$IgnoreWhitespaces = 1;
$CaseSensitive = 0;
$AutoSetParent = 0;
$NoWhiteSpaces = -999;
$CheckXMLBeforeParsing = 1;
$DieOnBadXML = 1;

$IgnoreDeepRecursionWarnings = 1;

sub Log
{
    my $class = shift;
    
    print STDERR "XML::Mini LOG MESSAGE:" ;
    print STDERR join(" ", @_) . "\n";
}

sub Error
{
    my $class = shift;
    
	my $errMsg =  "XML::Mini Error MESSAGE:" . join(" ", @_) . "\n";

    print STDERR $errMsg;
    
	die $errMsg;
}

sub escapeEntities
{
    my $class = shift;
    my $toencode = shift;
    
    return undef unless (defined $toencode);
    
    $toencode=~s/&/&amp;/g;
    $toencode=~s/\"/&quot;/g;
    $toencode=~s/>/&gt;/g;
    $toencode=~s/</&lt;/g;
    $toencode=~s/([\xA0-\xFF])/"&#".ord($1).";"/ge;
    return $toencode;
}

sub ignoreDeepRecursionWarning {

	# we do deep recursion... but it's ok, stop warning...
	$SIG{__WARN__} = sub {
                        my $msg = shift;
                        print STDERR $msg if ($msg !~ /Deep recursion/);
	};
}



1;
__END__

=head1 NAME

XML::Mini - Perl implementation of the XML::Mini XML create/parse interface.

=head1 SYNOPSIS

	use XML::Mini::Document;
	
	use Data::Dumper;
	
	
	###### PARSING XML #######
	
	# create a new object
	my $xmlDoc = XML::Mini::Document->new();
	
	# init the doc from an XML string
	$xmlDoc->parse($XMLString);
	
	# You may use the toHash() method to automatically
	# convert the XML into a hash reference
	my $xmlHash = $xmlDoc->toHash();
	
	print Dumper($xmlHash);
	
	
	# You can also manipulate the elements like directly, like this:	
	
	# Fetch the ROOT element for the document
	# (an instance of XML::Mini::Element)
	my $xmlRoot = $xmlDoc->getRoot();
	
	# play with the element and its children
	# ...
	my $topLevelChildren = $xmlRoot->getAllChildren();
	
	foreach my $childElement (@{$topLevelChildren})
	{
		# ...
	}
	
	
	###### CREATING XML #######
	
	# Create a new document from scratch
	
	my $newDoc = XML::Mini::Document->new();
	
	# This can be done easily by using a hash:
	my $h = {	
	 'spy'	=> {
		'id'	=> '007',
		'type'	=> 'SuperSpy',
		'name'	=> 'James Bond',
		'email'	=> 'mi5@london.uk',
		'address'	=> 'Wherever he is needed most',
		},
	};

	$newDoc->fromHash($h);
 
	
	
	# Or new XML can also be created by manipulating 
	#elements directly:
	
	my $newDocRoot = $newDoc->getRoot();
	
	# create the <? xml ?> header
	my $xmlHeader = $newDocRoot->header('xml');
	# add the version 
	$xmlHeader->attribute('version', '1.0');
	
	my $person = $newDocRoot->createChild('person');
	
	my $name = $person->createChild('name');
	$name->createChild('first')->text('John');
	$name->createChild('last')->text('Doe');
	
	my $eyes = $person->createChild('eyes');
	$eyes->attribute('color', 'blue');
	$eyes->attribute('number', 2);
	
	# output the document
	print $newDoc->toString();
	
	
This example would output :

 

 <?xml version="1.0"?>
  <person>
   <name>
    <first>
     John
    </first>
    <last>
     Doe
    </last>
  </name>
  <eyes color="blue" number="2" />
  </person>


  
  
  
=head1 DESCRIPTION

XML::Mini is a set of Perl classes that allow you to access XML data and create valid XML output with a tree-based hierarchy of elements.  The MiniXML API has both Perl and PHP implementations.

It provides an easy, object-oriented interface for manipulating XML documents and their elements.  It is currently being used to send requests and understand responses from remote servers in Perl or PHP applications.  An XML::Mini based parser is now being tested within the RPC::XML framework.

XML::Mini does not require any external libraries or modules and is pure Perl.  If available, XML::Mini will use the Text::Balanced module in order to escape limitations of the regex-only approach (eg "cross-nested" tag parsing).


The Mini.pm module includes a number of variables you may use to tweak XML::Mini's behavior.  These include:


$XML::Mini::AutoEscapeEntities - when greater than 0, the values set for nodes are automatically escaped, thus
$element->text('4 is > 3') will set the contents of the appended node to '4 is &gt; 3'.  Default setting is 1.


$XML::Mini::IgnoreWhitespaces - when greater than 0, extraneous whitespaces will be ignored (maily useful when parsing).  Thus
<mytag>       Hello There        </mytag> will be parsed as containing a text node with contents 'Hello There' instead 
of '       Hello There        '.  Default setting is 1.


$XML::Mini::CaseSensitive - when greater than 0, element names are treated as case sensitive.  Thus, $element->getElement('subelement') and $element->getElement('SubElement') will be equivalent.  Defaults to 0.


=head1 Class methods


=head2 escapeEntites TOENCODE

This method returns ToENCODE with HTML sensitive values
(eg '<', '>', '"', etc) HTML encoded.

=cut

=head2 Log MESSAGE

Logs the message to STDERR

=head2 Error MESSAGE

Logs MESSAGE and exits the program, calling exit()


=head2 ignoreDeepRecursionWarning

XML::Mini uses deep recursion on big XML docs, this is normal.  But the warnings are a pain.  
$XML::Mini::IgnoreDeepRecursionWarnings is set to TRUE by default, and ignoreDeepRecursionWarning() is called 
by XML::Mini::Document if it is set.  To bypass this behavior, 

 
 
	use XML::Mini;
	
	$XML::Mini::IgnoreDeepRecursionWarnings = 0;
	
	use XML::Mini::Document;
	
	# ...




=head1 AUTHOR


Copyright (C) 2002-2008 Patrick Deegan, Psychogenic Inc.

Programs that use this code are bound to the terms and conditions of the GNU GPL (see the LICENSE file). 
If you wish to include these modules in non-GPL code, you need prior written authorisation 
from the authors.


This library is released under the terms of the GNU GPL version 3, making it available only for 
free programs ("free" here being used in the sense of the GPL, see http://www.gnu.org for more details). 
Anyone wishing to use this library within a proprietary or otherwise non-GPLed program MUST contact psychogenic.com to 
acquire a distinct license for their application.  This approach encourages the use of free software 
while allowing for proprietary solutions that support further development.


=head2 LICENSE

    XML::Mini::Element module, part of the XML::Mini XML parser/generator package.
    Copyright (C) 2002-2008 Patrick Deegan
    All rights reserved
    
    XML::Mini is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    XML::Mini is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with XML::Mini.  If not, see <http://www.gnu.org/licenses/>.




=head1 SEE ALSO

XML::Mini::Document, XML::Mini::Element

http://minixml.psychogenic.com

=cut
