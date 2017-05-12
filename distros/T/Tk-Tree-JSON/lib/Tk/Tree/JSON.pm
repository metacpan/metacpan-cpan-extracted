package Tk::Tree::JSON;

# Tk::Tree::JSON - JSON tree widget

# Copyright (c) 2008-2015 José Santos. All rights reserved.
# This program is free software. It can be redistributed and/or modified under 
# the same terms as Perl itself.

use strict;
use warnings;
use Carp;

BEGIN {
	use vars qw($VERSION @ISA);
	require Tk::Tree;
	require JSON;
	require Tk::Derived;
	$VERSION	= '0.04';
	@ISA		= qw(Tk::Derived Tk::Tree);
}

Construct Tk::Widget 'JSON';

sub Tk::Widget::ScrolledJSON { shift->Scrolled('JSON' => @_) }

my $json_parser = undef;	# singleton JSON parser

# ConfigSpecs default values
my $VALUE_MAX_LENGTH = 80;

sub Populate {
	my ($myself, $args) = @_;
	$myself->SUPER::Populate($args);
	$myself->ConfigSpecs(
		-arraysymbol		=> ["PASSIVE", "arraySymbol", 
								"ArraySymbol", '[]'],
		-objectsymbol		=> ["PASSIVE", "objectSymbol", 
								"ObjectSymbol", '{}'],
		-namevaluesep		=> ["PASSIVE", "nameValueSep", 
								"NameValueSep", ': '],
		-valuemaxlength		=> ["METHOD", "valueMaxLength", 
								"VALUEMaxLength", $VALUE_MAX_LENGTH],
		-valuelongsymbol	=> ["PASSIVE", "valueLongSymbol", 
								"VALUELongSymbol", '...'],
		-itemtype			=> ["SELF", "itemType", "ItemType", 'text']
	);
}

# ConfigSpecs methods

# get/set max number of characters for displaying of JSON text values
sub valuemaxlength {
	my ($myself, $args) = @_;
	if (@_ > 1) {
		$myself->_configure(-valuemaxlength => &_value_max_length($args));
	}
	return $myself->_cget('-valuemaxlength');
}

# validate given max number of characters for displaying of JSON text values
# return given number if it is valid, $VALUE_MAX_LENGTH otherwise
sub _value_max_length {
	$_ = shift;
	/^\+?\d+$/ ? $& : &{ sub {
		carp "Attempt to assign an invalid value to -valuemaxlength: '$_' is" .
			" not a positive integer. Default value ($VALUE_MAX_LENGTH)" . 
			" will be used instead.\n";
		$VALUE_MAX_LENGTH
	}};
}

# application programming interface

sub load_json_file {	# load_json_file($json_filename)
	my ($myself, $json_file) = @_;
	if (!$myself->info('exists', '0')) {
		local $/ = undef;
		open FILE, $json_file or die "Could not open file $json_file: $!";
		my $json_string = <FILE>;
		close FILE;
		$myself->_load_json($myself->addchild(''), 
			&_json_parser->decode($json_string));
		$myself->autosetmode;	# set up automatic handling of open/close events
	} else {
		carp "A JSON document has already been loaded into the tree." .
			" JSON file $json_file will not be loaded.";
	}
}

sub load_json_string {	# load_json_string($json_string)
	my ($myself, $json_string) = @_;
	if (!$myself->info('exists', '0')) {
		$myself->_load_json($myself->addchild(''), 
			&_json_parser->decode($json_string));
		$myself->autosetmode;# set up automatic handling of open/close events
	} else {
		carp "A JSON document has already been loaded into the tree." .
			" JSON string will not be loaded.";
	}
}

sub get_value {	# get_value()
	my $myself = shift;
	$myself->entrycget($myself->selectionGet(), '-data');
}

# helper methods

# _json_parser(): get a JSON::Parser instance.
sub _json_parser {
	defined($json_parser) ? $json_parser : $json_parser = JSON->new
}

# _load_json($parent_path, $struct): load JSON elems under entry at $parent_path
sub _load_json {
	my ($myself, $parent_path, $struct) = ($_[0], $_[1], $_[2]);
	my $ref_type = ref $struct;
	my $text = ($myself->entrycget($parent_path, '-text') or '');
	my $entry_path;
	if ('HASH' eq $ref_type) {				# json object
		$myself->entryconfigure($parent_path, 
			-text => $text . $myself->cget('-objectsymbol')
		);
		while (my ($name, $value) = each %$struct) {
			$entry_path = $myself->addchild($parent_path, 
				-text => $name . $myself->cget('-namevaluesep')
			);
			$myself->_load_json($entry_path, $value);
		}
	} elsif ('ARRAY' eq $ref_type) {	# json array
		$myself->entryconfigure($parent_path, 
			-text => $text . $myself->cget('-arraysymbol')
		);
		foreach (@$struct) {
			$entry_path = $myself->addchild($parent_path);
			$myself->_load_json($entry_path, $_);
		}
	} else {													# json string, number, true, false or null
		$myself->entryconfigure($parent_path, -data => $struct);
		if (defined $struct) {
			$struct = $struct ? 'true' : 'false' if JSON::is_bool($struct);
		} else {
			$struct = 'null';
		}
		$myself->entryconfigure($parent_path,
			-text => $text . $myself->_format_text($struct));
	}
}

sub _format_text { # _format_text($text): format/return text accordingly
	my ($myself, $text) = @_;
	my $value_max_length = $myself->cget('-valuemaxlength');
	length($text) > $value_max_length 
		? substr($text, 0, $value_max_length) .  $myself->cget('-valuelongsymbol')
		: $text;
}

1;

__END__

=head1 NAME

Tk::Tree::JSON - JSON tree widget

=head1 SYNOPSIS

 use Tk::Tree::JSON;

 $top = MainWindow->new;

 $json_tree = $top->JSON(?options?);
 $json_tree = $top->ScrolledJSON(?options?);

 $json_tree->load_json_file("file.json");
 $json_tree->load_json_string(
 	'[2008, "Tk::Tree::JSON", null, false, true, 30.12]');

=head1 DESCRIPTION

B<JSON> graphically displays and allows for interaction with the tree of a JSON document.

A JSON document may be loaded from either a JSON file or a JSON string.

Target applications may include JSON viewers, editors and the like. 

=head1 STANDARD OPTIONS

B<JSON> is a subclass of L<Tk::Tree> and therefore inherits all of its 
standard options. 

Details on standard widget options can be found at L<Tk::options>.

=head1 TREE RENDERING

Each JSON tree node is rendered according to the type of its underlying JSON 
structure and to set widget options:

=over 4

=item * JSON string or number: as is

=item * JSON C<true> or C<false>: C<true> or C<false>, respectively

=item * JSON C<null>: C<null>

=item * JSON array: B<arraySymbol>

=item * JSON object: B<objectSymbol>

=item * JSON C<name>/C<value> pair: concatenation of:

=over 8

=item * C<name>

=item * B<nameValueSep>

=item * C<value>, as per these rules

=back

=back

Additionally, a JSON string, number, C<true>, C<false>, C<null> or a C<value> of
any of these types within a name/C<value> pair is shortened to B<valueMaxLength>
characters if its length exceeds this value. In this case, B<valueLongSymbol> is
appended to the shortened string.

Examples:

=over 4

=item * A tree node refers to string "ABCDEFGHIJ", B<valueMaxLength> is set to C<5> 
and B<valueLongSymbol> to C<...>: the tree node is rendered as as 
C<ABCDE...>

=item * A tree node refers to name/value pair "STRING OF 10 CHARACTERS"/"ABCDEFGHIJ", 
B<valueMaxLength> is set to C<5>, B<valueLongSymbol> to C<...> and 
B<nameValueSep> to C<::>: the tree node is rendered as as 
C<STRING OF 10 CHARACTERS::ABCDE...>

=back

=head1 WIDGET-SPECIFIC OPTIONS

The following options control the rendering of tree nodes:

=over 4

=item Name:		B<arraySymbol>

=item Class:		B<ArraySymbol>

=item Switch:		B<-arraysymbol>

Set the symbol representing a JSON array.

Default value: C<[]>

=item Name:		B<objectSymbol>

=item Class:		B<ObjectSymbol>

=item Switch:		B<-objectsymbol>

Set the symbol representing a JSON object.

Default value: C<{}>

=item Name:		B<nameValueSep>

=item Class:		B<NameValueSep>

=item Switch:		B<-namevaluesep>

Set the separator between the name and value of a JSON object pair.

Default value: C<: >

=item Name:		B<valueMaxLength>

=item Class:		B<VALUEMaxLength>

=item Switch:		B<-valuemaxlength>

Set the maximum number of characters to be displayed for a JSON string, number,
C<true>, C<false> or C<null>.

Default value: C<80>

=item Name:		B<valueLongSymbol>

=item Class:		B<VALUELongSymbol>

=item Switch:		B<-valuelongsymbol>

Set the symbol to append to a JSON string, number, C<true>, C<false> or C<null>
value whose length exceeds B<valueMaxLength> characters.

Default value: C<...>

=back

=head1 WIDGET METHODS

The B<JSON> method creates a widget object. This object supports the 
B<configure> and B<cget> methods described in L<Tk::options> which can be used 
to enquire and modify the options described above. The widget also inherits 
all the methods provided by the generic L<Tk::Widget> class.

A B<JSON> is not scrolled by default. The B<ScrolledJSON> method creates a 
scrolled B<JSON>.

The following additional methods are available for B<JSON> widgets:

=over 4

=item $json_tree->B<load_json_file>(F<$json_filename>)

Load a JSON document from a file into the tree. If the tree is already loaded 
with a JSON document, no reloading occurs and a warning message is issued.

Return value: none.

Example:

 # load JSON document from file document.json into the tree
 $json_tree->load_json_file('document.json');

=back

=over 4

=item $json_tree->B<load_json_string>(F<$json_string>)

Load a JSON document represented by a string into the tree. If the tree is 
already loaded with a JSON document, no reloading occurs and a warning message 
is issued.

Return value: none.

Example:

 # load JSON document from json string into the tree
 $json_tree->load_json_string('{"name1": "text1", "name2": "text2"}');

=back

=over 4

=item $json_tree->B<get_value>()

For the currently selected element, retrieve the value of its underlying JSON 
structure according to the following logic:

=over 8

=item * JSON structure is either a string or number: string or number as is

=item * JSON structure is either C<true> or C<false>: C<JSON::true> or 
C<JSON::false>, respectively

=item * JSON structure is a C<name>/C<value> pair: value of JSON structure 
C<value>

=item * JSON structure is none of the above: undef

=back

Return value: For the currently selected element, the value of its underlying 
JSON structure according to the above rules.

Example:

 # retrieve value of currently selected element
 $value = $json_tree->get_value();

 # inspect value
 if (defined $value) {
   if (JSON::is_bool($value)) {
     print "JSON boolean " . ($value ? 'true' : 'false') . "\n";
   } else {
     print "JSON string or number $value\n";
   }
 } else {
   print "JSON null or JSON array or JSON object\n";
 }

=back

=head1 EXAMPLES

A JSON viewer using B<Tk::Tree::JSON> can be found in the F<examples> directory 
included with this module. It features two panes where the upper one displays
the JSON tree itself and the lower one the value of the currently selected 
node along with type information. A sample JSON file is also provided.

=head1 VERSION

B<Tk::Tree::JSON> version 0.04.

=head1 AUTHOR

Santos, José.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-tk-tree-json at rt.cpan.org> or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-Tree-JSON>. The author will 
be notified and there will be automatic notification about progress on bugs as 
changes are made.

=head1 SUPPORT

Documentation for this module can be found with the following perldoc command:

    perldoc Tk::Tree::JSON

Additional information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-Tree-JSON>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-Tree-JSON>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-Tree-JSON>

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-Tree-JSON>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2015 José Santos. All rights reserved.

This program is free software. It can redistributed and/or modified under the 
same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Thanks to my family.

=head1 DEDICATION

I dedicate B<Tk::Tree::JSON> to Dr. Gabriel.

=cut
