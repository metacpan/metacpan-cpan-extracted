package Tk::Tree::XML;

# Tk::Tree::XML - XML tree widget

# Copyright (c) 2008 José Santos. All rights reserved.
# This program is free software. It can be redistributed and/or modified under 
# the same terms as Perl itself.

use strict;
use warnings;
use Carp;

BEGIN {
	use vars qw($VERSION @ISA);
	require Tk::Tree;
	require XML::Parser;
	require Tk::Derived;
	$VERSION	= '0.01';
	@ISA		= qw(Tk::Derived Tk::Tree);
}

Construct Tk::Widget 'XML';

sub Tk::Widget::ScrolledXML { shift->Scrolled('XML' => @_) }

# ConfigSpecs default values
my $PCDATA_MAX_LENGTH = 80;

sub Populate {
	my ($myself, $args) = @_;
	$myself->SUPER::Populate($args);
	$myself->ConfigSpecs(
		-pcdatamaxlength		=> ["METHOD", "pcdataMaxLength", 
									"PCDATAMaxLength", $PCDATA_MAX_LENGTH],
		-pcdatalongsymbol		=> ["PASSIVE", "pcdataLongSymbol", 
									"PCDATALongSymbol", '...'],
		-pcdatapreservespace	=> ["PASSIVE", "pcdataPreserveSpace", 
									"PCDATAPreserveSpace", 0],
		-itemtype				=> ["SELF", "itemType", "ItemType", 'text']
	);
}

# ConfigSpecs methods

# get/set maximum number of characters for visualization of pcdata contents
sub pcdatamaxlength {
	my ($myself, $args) = @_;
	if (@_ > 1) {
		$myself->_configure(-pcdatamaxlength => &_pcdata_max_length($args));
	}
	return $myself->_cget('-pcdatamaxlength');
}

# validate given max number of characters for visualization of pcdata contents
# return given number if it is valid, $PCDATA_MAX_LENGTH otherwise
sub _pcdata_max_length {
	$_ = shift;
	/^\+?\d+$/ ? $& : &{ sub {
		carp "Attempt to assign an invalid value to -pcdatamaxlength: '$_' is" .
			" not a positive integer. Default value ($PCDATA_MAX_LENGTH)" . 
			" will be used instead.\n";
		$PCDATA_MAX_LENGTH
	}};
}

# application programming interface

sub load_xml_file {	# load_xml_file($xml_filename)
	my ($myself, $xmlfile) = @_;
	my @array = (1, 2, 3);
	if (!$myself->info('exists', '0')) {
		$myself->_load_xml('', &_xml_parser->parsefile($xmlfile));
		$myself->autosetmode;# set up automatic handling of open/close events
	} else {
		carp "An XML document has already been loaded into the tree." .
			" XML file $xmlfile will not be loaded.";
	}
}

sub load_xml_string {	# load_xml_string($xml_string)
	my ($myself, $xmlstring) = @_;
	if (!$myself->info('exists', '0')) {
		$myself->_load_xml('', &_xml_parser->parse($xmlstring));
		$myself->autosetmode;# set up automatic handling of open/close events
	} else {
		carp "An XML document has already been loaded into the tree." .
			" XML string will not be loaded.";
	}
}

sub get_name {	# get_name()
	my $myself = shift;
	my $entry_path = $myself->selectionGet();
	my $is_mixed = ref($myself->entrycget($entry_path, '-data'));
	$is_mixed ? $myself->entrycget($entry_path, '-text') : undef;
}

sub get_attrs {	# get_attrs()
	my $myself = shift;
	my $attrs = $myself->entrycget($myself->selectionGet(), '-data');
	ref($attrs) ? %{$attrs} : undef;
}

sub get_text {	# get_text()
	my $myself = shift;
	my $text = $myself->entrycget($myself->selectionGet(), '-data');
	ref($text) ? undef : $text;
}

sub is_mixed {	# is_mixed()
	my $myself = shift;
	'HASH' eq ref($myself->entrycget($myself->selectionGet(), '-data'));
}

sub is_pcdata {	# is_pcdata()
	my $myself = shift;
	!$myself->is_mixed();
}

# helper methods

sub _xml_parser {	# _xml_parser(): get an XML::Parser instance.
	new XML::Parser(Style => 'Tree', ErrorContext => 2)
}

# _load_xml($parent_path, @children): load XML elems under entry at $parent_path
# @children is a list of tag/content pairs where each pair is such as:
# - ($element_tag, [%element_attrs, @element_children])	<= element is mixed
# - 0, 'pcdata contents'								<= element is PCDATA
# for each entry, XML -data and -text are set, respectively, to:
# attributes and element tag							<= element is mixed
# pcdata content and formatted pcdata content			<= element is PCDATA
sub _load_xml {
	my ($myself, $parent_path, @children) = ($_[0], $_[1], @{$_[2]});
	my $entry_path;
	while (@children) {
		my ($elem_tag, $elem_content) = (shift @children, shift @children);
		if (!ref $elem_content) {	# element is #PCDATA
			$elem_content =~ s/[\n\t ]*(.*)[\n\t ]*/$1/	# trim spacing
				unless $myself->cget('-pcdatapreservespace') eq 1;
			if ('' ne $elem_content) {
				$entry_path = $myself->addchild(
					$parent_path, -data => $elem_content, 
					-text => $myself->_format_pcdata($elem_content), 
				);
			}
		} else {	# element is not pcdata
			$entry_path = $myself->addchild($parent_path, 
				-data => $elem_content->[0], -text => $elem_tag
			);
			shift(@$elem_content);	# shift element attributes off
			$myself->_load_xml($entry_path, $elem_content) 
				unless !scalar @$elem_content; # recursively process children
		}
	}
}

sub _format_pcdata { # _format_pcdata($pcdata): format/return pcdata accordingly
	my ($myself, $pcdata) = @_;
	my $pcdata_max_length = $myself->cget('-pcdatamaxlength');
	length($pcdata) > $pcdata_max_length 
		? substr($pcdata, 0, $pcdata_max_length) . 
			$myself->cget('-pcdatalongsymbol')
		: $pcdata;
}

1;

__END__

=head1 NAME

Tk::Tree::XML - XML tree widget

=head1 SYNOPSIS

 use Tk::Tree::XML;

 $top = MainWindow->new;

 $xml_tree = $top->XML(?options?);
 $xml_tree = $top->ScrolledXML(?options?);

 $xml_tree->load_xml_file("file.xml");
 $xml_tree->load_xml_string('<root><child /></root>');

=head1 DESCRIPTION

B<XML> graphically displays the tree structure of XML documents loaded 
from either an XML file or an XML string. 

B<XML> enables Perl/Tk applications with a widget that allows visual 
representation and interaction with XML document trees. 

Target applications may include XML viewers, editors and the like. 

=head1 STANDARD OPTIONS

B<XML> is a subclass of L<Tk::Tree> and therefore inherits all of its 
standard options. 

Details on standard widget options can be found at L<Tk::options>.

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name:		B<pcdataMaxLength>

=item Class:		B<PCDATAMaxLength>

=item Switch:		B<-pcdatamaxlength>

Set the maximum number of characters to be displayed for PCDATA elements. 
Content of such elements is trimmed to a length of B<pcdataMaxLength> characters.

Default value: C<80>. 

=item Name:		B<pcdataLongSymbol>

=item Class:		B<PCDATALongSymbol>

=item Switch:		B<-pcdatalongsymbol>

Set the symbol to append to PCDATA content with length greater than 
B<pcdataMaxLength> characters.

Default value: C<...>. 

=item Name:		B<pcdataPreserveSpace>

=item Class:		B<PCDATAPreserveSpace>

=item Switch:		B<-pcdatapreservespace>

Specify whether space characters surrounding PCDATA elements should be 
preserved or not. Such characters are preserved if this option is set to 1 and 
not preserved if set to 0. 

Default value: 0.

=back

=head1 WIDGET METHODS

The B<XML> method creates a widget object. This object supports the 
B<configure> and B<cget> methods described in L<Tk::options> which can be used 
to enquire and modify the options described above. The widget also inherits 
all the methods provided by the generic L<Tk::Widget> class.

An B<XML> is not scrolled by default. The B<ScrolledXML> method creates a scrolled B<XML>.

The following additional methods are available for B<XML> widgets:

=over 4

=item $xml_tree->B<load_xml_file>(F<$xml_filename>)

Load an XML document from a file into the tree. If the tree is already loaded 
with an XML document, no reloading occurs and a warning message is issued.

Return value: none.

Example(s):

 # load XML document from file document.xml into the tree
 $xml_tree->load_xml_file('document.xml');

=back

=over 4

=item $xml_tree->B<load_xml_string>(F<$xml_string>)

Load an XML document represented by a string into the tree. If the tree is 
already loaded with an XML document, no reloading occurs and a warning message 
is issued.

Return value: none.

Example(s):

 # load XML document from xml string into the tree
 $xml_tree->load_xml_string('<root><child /></root>');

=back

=over 4

=item $xml_tree->B<get_name>()

Retrieve the name of the currently selected XML element.

Return value: name of selected element if it is mixed, undef if it is PCDATA.

Example(s):

 # retrieve name of currently selected element
 $element_name = $xml_tree->get_name();

=back

=over 4

=item $xml_tree->B<get_attrs>()

Retrieve the attribute list of the currently selected XML element.

Return value: attributes of selected element if it is mixed, undef if it is 
PCDATA. Attributes are returned as an associative array, where each key/value 
pair represent an attribute name/value, respectively.

Example(s):

 # retrieve attribute list of currently selected element
 %attributes = $xml_tree->get_attrs();

=back

=over 4

=item $xml_tree->B<get_text>()

Retrieve the content of the currently selected XML element. 

Return value: Text content if selected element is PCDATA, undef if it is mixed.

Example(s):

 # retrieve content text of currently selected element
 $text = $xml_tree->get_text();

=back

=over 4

=item $xml_tree->B<is_mixed>()

Indicate whether the currently selected element is mixed or not. If the element
is not mixed then it is PCDATA. 

Return value: TRUE if the currently selected element is mixed, FALSE if it is 
PCDATA.

Example(s):

 # determine if selected element is mixed or not
 print "element is " . ($xml_tree->is_mixed() ? 'mixed' : 'PCDATA');

=back

=over 4

=item $xml_tree->B<is_pcdata>()

Indicate whether the currently selected element is PCDATA or not. If the 
element is not PCDATA then it is mixed. 

Return value: TRUE if the currently selected element is PCDATA, FALSE if it is 
mixed.

Example(s):

 # determine if selected element is PCDATA or not
 print "element is " . ($xml_tree->is_pcdata() ? 'PCDATA' : 'mixed');

=back

=head1 EXAMPLES

An XML viewer using B<Tk::Tree::XML> can be found in the F<examples> directory 
included with this module. 

=head1 VERSION

B<Tk::Tree::XML> version 0.01.

=head1 AUTHOR

Santos, José.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-tk-tree-xml at rt.cpan.org> or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-Tree-XML>. The author will 
be notified and there will be automatic notification about progress on bugs as 
changes are made.

=head1 SUPPORT

Documentation for this module can be found with the following perldoc command:

    perldoc Tk::Tree::XML

Additional information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-Tree-XML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-Tree-XML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-Tree-XML>

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-Tree-XML>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 José Santos. All rights reserved.

This program is free software. It can redistributed and/or modified under the 
same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Thanks to Cotonete, Droit, Pistacho and Barriguita.

=head1 DEDICATION

I dedicate B<Tk::Tree::XML> to my GrandMother.

=cut
