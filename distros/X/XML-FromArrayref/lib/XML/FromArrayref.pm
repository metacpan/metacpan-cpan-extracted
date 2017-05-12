package XML::FromArrayref;

use 5.006;
use strict;
use warnings;

use base qw( Exporter );
our @EXPORT = qw( XML );
our @EXPORT_OK = qw( start_tag end_tag XMLdecl doctype );
our %EXPORT_TAGS = (
	TAGS => [qw( start_tag end_tag )],
	PROLOG => [qw( XMLdecl doctype )]
);

use HTML::Entities;
use URI::Escape;

=head1 NAME

XML::FromArrayref - Output XML described by a Perl data structure

=head1 VERSION

Version 1.02

=cut

our $VERSION = '1.02';

=head1 SYNOPSIS

  use XML::FromArrayref;
  print XML [ html => [ head => [ title => 'My Web page' ] ], [ body => 'Hello' ] ];

=head1 EXPORT

This module exports an XML() function that lets you easily print valid XML without embedding it in your Perl code.

=head1 SUBROUTINES/METHODS

=head2 XML(@)

Takes a list of strings and arrayrefs describing XML content and returns the XML string. The strings are encoded; each arrayref represents an XML element, as follows:

  [ $tag_name, $attributes, @content ]

=head3 $tag_name

evaluates to an XML tag name. If $tag_name is false then the whole element is replaced by its content.

If an arrayref's first element is another arrayref instead of an tag name, then the value of the first item of that array will be included in the XML string but will not be encoded. This lets you include text in the XML that has already been entity-encoded.

=head3 $attributes

is an optional hashref defining the element's attributes. If an attribute's value is undefined then the attribute will not appear in the generated XML string. Attribute values will be encoded. If there isn't a hashref in the second spot in the element-definition list then the element won't have any attributes in the generated XML.

=head3 @content

is another list of strings and arrayrefs, which will be used to generate the content of the element. If the content list is empty, then the element has no content and will be represented in the generated XML string by a single empty-element tag.

=cut

sub XML (@) {
	join '', grep defined $_, map {
		ref $_ eq 'ARRAY' ? element( @$_ ) : encode_entities( $_, '&<' )
	} @_;
}

=head2 element()

Recursively renders XML elements from arrayrefs.

=cut

sub element {
	my ( $tag_name, $attributes, @content ) = @_;

	# If an element's name is an array ref then it's
	# really text to print without encoding
	return $tag_name->[0] if ref $tag_name eq 'ARRAY';

	# If the second item in the list is not a hashref,
	# then the element has no attributes
	if ( defined $attributes and ref $attributes ne 'HASH' ) {
		unshift @content, $attributes;
		undef $attributes;
	}

	# If the first expression in the list is false, then skip
	# the element and return its content instead
	return XML( @content ) if not $tag_name;

	# Return the element start tag, with its formatted and
	# encoded attributes, and the content and end tag; or,
	# if no content, a self-closing empty element
	join '', '<', $tag_name, attributes( %$attributes ),
        @content ? ( '>', XML( @content ), "</$tag_name>" ) : '/>'
}

=head2 start_tag()

Takes a list with an element name and an optional hashref defining the element's attributes, and returns just the opening tag of the element. This and end_tag() are useful in those occasions when you really want to print out XML piecewise procedurally, rather than building the whole page in memory.

=cut

sub start_tag {
	my ( $tag_name, $attributes ) = @_;

	join '', grep $_,
		'<', $tag_name, attributes( %$attributes ), '>';
}

=head2 end_tag()

Just takes an element name and returns the end tag for that element.

=cut

sub end_tag { "</$_[0]>" }

=head2 attributes()

Takes a hash of XML element attributes and returns an encoded string for use in a tag.

=cut

sub attributes {

	return unless my @attributes = @_;

	my @html;
	while ( my ($name, $value) = splice @attributes, 0, 2 ) {
		if ( defined $value ) {
			push @html, join '', $name, '="', encode_entities( $value, '&<"' ), '"';
		}
	}
	join ' ', '', @html;
}

=head2 XMLdecl()

This makes it easy to add a valid XML declaration to your document.

=cut

sub XMLdecl {
    my ( $version, $encoding, $standalone ) = @_;

    $version  ||= '1.0';

    join '', '<?xml', attributes( version => $version, encoding => $encoding, standalone => $standalone ), '?>';
}

=head2 doctype()

This makes it easy to add a valid doctype declaration to your document.

=cut

sub doctype {
    my ( $root, $URI, $pubID, $subset ) = @_;

    $root   ||= 'XML';
    $URI    &&= uri_escape( $URI, '\x0-\x1F\x7F-\xFF <>"{}|\^``"' );
    $URI    &&= qq("$URI");
    $pubID  &&= qq("$pubID");
    $subset &&= "[ $subset ]";

    join( ' ', grep defined $_,
        '<!DOCTYPE', $root,
        $pubID ? ('PUBLIC', $pubID, $URI) : $URI && ('SYSTEM', $URI),
        $subset
    ) . '>';
}

=head1 EXAMPLES

Note that I've formatted the output XML for clarity - the XML() function returns it all machine-readable and compact.

=head2 Simple content

Strings are just encoded and printed, so

  print XML 'Hi there, this & that';

would print

  Hi there, this &amp; that

=head2 Literal content

If an element's name is an arrayref, its first item is printed without being encoded; this lets you include text that is already encoded by double-bracketing it:

  print XML [ copyright => [[ '&copy; Angel Networks&trade;' ]] ];

would print

  <copyright>&copy; Angel Networks&trade;</copyright>

=head2 Using map to iterate, and optional elements

You can map any element over a list to iterate it, and by testing the value being mapped over can wrap some values in sub-elements:

  print XML map [ number => [ $_ > 100 && large => $_ ] ], 4, 450, 12, 44, 74, 102;

would print

  <number>4<number>
  <number><large>450</large></number>
  <number>12</number>
  <number>44</number>
  <number>74</number>
  <number><b>102</b></number>

=head2 Optional attributes

Similarly, by testing the value being mapped over in the attributes hash, you can set an attribute for only some values. Note that you have to explicitly return undef to skip the attribute since 0 is a valid value for an attribute.

  print XML [ states =>
    map
      [ state => { selected => $_ eq $c{state} || undef }, $_ ],
      @states
  ];

would print

  <states>
    <state>Alabama</state>
    <state selected="1">Alaska</state>
    <state>Arkansas</state>
    ...
  </state>

assuming $c{state} equalled 'Alaska'.

=head2 Printing XML tags one at a time

Sometimes you really don't want to build the whole document before printing it; you'd rather loop through some data and print an element at a time. The start_tag and end_tag functions will help you do this:

  print start_tag( [ document => { columns => 3 } ] );
  print end_tag( 'document' );

would print

  <document columns="3">
  </document>

=head2 XML declaration

You can print an XML declaration with the XMLdecl() function.

  print XMLdecl();

would print the default XML declaration

  <?xml version="1.0" encoding="UTF-8"?>

but you can change the version and encoding by passing up to two arguments:

  print XMLdecl('1.1', 'CP-1252');

would print

  <?xml version="1.1" encoding="CP-1252"?>

=head2 Doctyoe

The doctype() function can be called without arguments to print a default doctype:

  print doctype();

  <!DOCTYPE XML>

or with one argument to set the root element name:

  print doctype('html');

  <!DOCTYPE html>

The second argument, if defined, is a URI; if no third argument is given, then it's printed as a private SYSTEM URI:

  print doctype('transaction', 'http://example.com/transaction.dtd');

  <!DOCTYPE transaction SYSTEM "http://example.com/transaction.dtd">

The third argument, if defined, is a public ID which will make the doctype public:

  print doctype('HTML', 'http://www.w3.org/TR/html4/strict.dtd', '-//W3C//DTD HTML 4.01//EN');

  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">

Finally, if a fourth argument is given, it's a internal subset, which could contain markup declarations for entities, elements, &c.

  print doctype('transaction', undef, undef, '<!ELEMENT description (#PCDATA)>' );

  <!DOCTYPE transaction [ <!ELEMENT description (#PCDATA)> ]>

=head1 SEE ALSO

L<The XML 1.0 specification|http://www.w3.org/TR/REC-xml/>

=head1 AUTHOR

Nic Wolff, <nic@angel.net>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/nicwolff/XML-FromArrayref/issues>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::FromArrayref

You can also look for information at:

=over 4

=item * This module on GitHub

L<https://github.com/nicwolff/XML-FromArrayref>

=item * GitHub request tracker (report bugs here)

L<https://github.com/nicwolff/XML-FromArrayref/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-FromArrayref>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-FromArrayref/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nic Wolff.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of XML::FromArrayref
