#!/usr/bin/perl

#####################################################################

=pod

This example demonstrates some things that are possible though they
might not be very sensfull in this context ;)

=cut

#####################################################################

use strict;
use warnings;
use XML::XMLWriter;
use POSIX;

my $version = '0.1';

my @parts = ('Download', 'Documentation', 'Contact', 'Bugs');
my $doc = new XML::XMLWriter;
my $html = $doc->createRoot();
$html->head()->title()->_pcdata('XML::XMLWriter Homepage');
my $body = $html->body();
$body->h1({style => 'text-align:center;'})->_pcdata('XML::XMLWriter');
my $p = $body->p({style => "text-align:center; font-size:9pt;"});
foreach $_ (@parts) {
$p->a({'href' => '#'.$_}, $_);
$p->_pcdata(' ');
}

$body->p()
  ->_pcdata('XMLWriter is a Perl 5 object class, its purpose is to make writing XML documents easier, cleaner, safer and standard conform. Its easier because of the object oriented way XML documents are written with XMLWriter. Its cleaner because of the simple but logical API and its safe and standard conform because of the automatically done checking against the the DTD.')
  ->br()
  ->br()
  ->_pcdata('But still: it might be a matter of taste whether one finds XMLWriter usefull or not and it probably has some bugs (i would appreciate a lot if you report them to me), many usefull features are missing, not implemented or not even thought of and perhaps the API with all its simpleness might be confusing though. So please tell me your opinion and tell me the way how you would make XMLWriter better. Its not so easy to develop a good API for this matter.')
  ->br()
  ->br()
  ->_pcdata('XMLWriter contains 3 packages: XMLWriter.pm which gives you the document object, Element.pm which provides the element/tag objects and PCData.pm which represents the parsed character data the document contains. There\'ll probably come more objects in feature releases. 
The most interesting class is Element.pm. It provides some methods you can call on every document element, but besides those methods it uses the AUTOLOAD feature of perl to expect every not known method name to be the name of a tag that should be added to the list of child tags of the element the method is called on. So calling "$html->head" will simply add a new element (the head element) to the list of child tags of the html element. The head object is returned.')
  ->br()
  ->br()
  ->_pcdata('XML::ParseDTD is supported by the ')
  ->a({href => 'http://fhg.freesources.org'}, 'fHG')->_parent()
  ->_pcdata('.');

foreach $_ (@parts) {
  $body->h2()->a({name => $_}, $_);
  my @arg = eval('get_part_'.$_.'($doc->get_dtd())') or die @!;
  #of course would be easier to pass the p() object and add directly on it (shorter!)
  #but i want to demonstrate the possibilities you have
  $body->p()->_push_child(@arg);
}

$body->hr()->div({style => 'font-style:italic'})->_pcdata('Last modified: ', POSIX::ctime(time()));
#$body->_pcdata('<test>&uml;');
$doc->print();

sub get_part_Download {
  my $dtd = shift;
  return(XML::XMLWriter::Element->new('a', $dtd, {href => "XML-XMLWriter-$version.tar.gz"}, "XML-XMLWriter-$version"),
	 XML::XMLWriter::PCData->new(' (older versions are available from '),
	 XML::XMLWriter::Element->new('a', $dtd, {href => 'http://backpan.cpan.org/authors/id/M/MO/MORNI/'}, 'http://backpan.cpan.org/authors/id/M/MO/MORNI/'),
	 XML::XMLWriter::PCData->new(')'));
}

sub get_part_Documentation {
  my $dtd = shift;
  return(XML::XMLWriter::Element->new('a', $dtd, {href => "XMLWriter.html"}, 'XMLWriter'),
	 XML::XMLWriter::Element->new('br', $dtd),
	 XML::XMLWriter::Element->new('a', $dtd, {href => "Element.html"}, 'XMLWriter::Element'),
	 XML::XMLWriter::Element->new('br', $dtd),
	 XML::XMLWriter::Element->new('a', $dtd, {href => "PCData.html"}, 'XMLWriter::PCData'));
}

sub get_part_Contact {
  my $dtd = shift;
  return('Email: ',
	 XML::XMLWriter::Element->new('a', $dtd, {href => 'moritz@freesources.org'}, 'moritz@freesources.org'),
	 XML::XMLWriter::Element->new('br', $dtd),
	 'IRC: irc.freenode.net #fHG');
}

sub get_part_Bugs {
  my $dtd = shift;
  return('Send bug reports to: ', 
	 XML::XMLWriter::Element->new('a', $dtd, {href => 'mailto:bug-XML-ParseDTD@rt.cpan.org'}, 'bug-XML-ParseDTD@rt.cpan.org'),
	' (if that doesn\'t work feel free to send me an email).');
}
