=head1 NAME

XML::Easy::SimpleSchemaUtil - help with simple kinds of XML schema

=head1 SYNOPSIS

	use XML::Easy::SimpleSchemaUtil qw(
		xml_s_canonise_chars xml_c_canonise_chars
		xml_c_subelements xml_c_chardata
	);

	$chardata = xml_s_canonise_chars($chardata);
	$content = xml_c_canonise_chars($content);
	$subelements = xml_c_subelements($content);
	$chars = xml_c_chardata($content);

=head1 DESCRIPTION

The rules by which some class of thing is encoded in XML constitute a
schema.  (A schema does not need to be codified in a formal language such
as Schematron: a natural-language specification can also be a schema.
Even if there is no explicit specification at all, the behaviour of
the interoperating processors of related XML documents constitutes a de
facto schema.)  Certain kinds of rule are commonly used in all manner
of schemata.  This module supplies functions that help to implement such
common kinds of rule, regardless of how a schema is specified.

This module processes XML data in the form used by L<XML::Easy>,
consisting of C<XML::Easy::Element> and C<XML::Easy::Content> objects
and twine arrays.  In this form, character data are stored fully decoded,
so they can be manipulated with no knowledge of XML syntax.

=cut

package XML::Easy::SimpleSchemaUtil;

{ use 5.006; }
use warnings;
use strict;

use Params::Classify 0.000 qw(is_ref);
use XML::Easy::Classify 0.006 qw(check_xml_chardata check_xml_content_twine);
use XML::Easy::NodeBasics 0.007
	qw(xml_content_object xml_content_twine xml_c_content_twine);
use XML::Easy::Syntax 0.000 qw($xml10_s_rx);

our $VERSION = "0.002";

use parent "Exporter";
our @EXPORT_OK = qw(
	xml_s_canonise_chars xs_charcanon xml_c_canonise_chars xc_charcanon
	xml_c_subelements xc_subelems xml_c_chardata xc_chars
);

sub _throw_data_error($) {
	my($msg) = @_;
	die "invalid XML data: $msg\n";
}

sub _throw_schema_error($) {
	my($msg) = @_;
	die "XML schema error: $msg\n";
}

=head1 FUNCTIONS

Each function has two names.  There is a longer descriptive name, and
a shorter name to spare screen space and the programmer's fingers.

=over

=item xml_s_canonise_chars(STRING, OPTIONS)

=item xs_charcanon(STRING, OPTIONS)

This function is intended to help in parsing XML data, in situations
where the schema states that some aspects of characters are not
entirely significant.  I<STRING> must be a plain Perl string consisting
of character data that is valid for XML.  The function examines the
characters, processes them as specified in the I<OPTIONS>, and returns
a modified version of the string.
I<OPTIONS> must be a reference to a hash, in which the permitted keys are:

=over

=item B<leading_wsp>

=item B<intermediate_wsp>

=item B<trailing_wsp>

Controls handling of sequences of whitespace characters.  The three
keys control, respectively, whitespace at the beginning of the string,
whitespace that is at neither the beginning nor the end, and whitespace at
the end of the string.  If the entire content of the string is whitespace,
it is treated as both leading and trailing.

The whitespace characters, for this purpose, are tab, linefeed/newline,
carriage return, and space.  This is the same set of characters that
are whitespace for the purposes of the XML syntax.

The value for each key may be:

=over

=item B<DELETE>

Completely remove the whitespace.  For situations where the whitespace is
of no significance at all.  (Common for leading and trailing whitespace,
but rare for intermediate whitespace.)

=item B<COMPRESS>

Replace the whitespace sequence with a single space character.
For situations where the presence of whitespace is significant but the
length and type are not.  (Common for intermediate whitespace.)

=item B<PRESERVE> (default)

Leave the whitespace unchanged.  For situations where the exact type of
whitespace is significant.

=back

=back

=cut

sub _canonise_chars($$) {
	my($string, $options) = @_;
	my $leading_wsp = exists($options->{leading_wsp}) ?
		$options->{leading_wsp} : "PRESERVE";
	if($leading_wsp eq "DELETE") {
		$string =~ s/\A$xml10_s_rx//o;
	} elsif($leading_wsp eq "COMPRESS") {
		$string =~ s/\A$xml10_s_rx/ /o;
	} elsif($leading_wsp ne "PRESERVE") {
		_throw_data_error("bad character canonicalisation option");
	}
	my $intermediate_wsp = exists($options->{intermediate_wsp}) ?
		$options->{intermediate_wsp} : "PRESERVE";
	if($intermediate_wsp eq "DELETE") {
		$string =~ s/(?!$xml10_s_rx)(.)$xml10_s_rx(?!$xml10_s_rx|\z)
				/$1/xsog;
	} elsif($intermediate_wsp eq "COMPRESS") {
		$string =~ s/(?!$xml10_s_rx)(.)$xml10_s_rx(?!$xml10_s_rx|\z)
				/$1 /xsog;
	} elsif($intermediate_wsp ne "PRESERVE") {
		_throw_data_error("bad character canonicalisation option");
	}
	my $trailing_wsp = exists($options->{trailing_wsp}) ?
		$options->{trailing_wsp} : "PRESERVE";
	if($trailing_wsp eq "DELETE") {
		$string =~ s/$xml10_s_rx\z//o;
	} elsif($trailing_wsp eq "COMPRESS") {
		$string =~ s/$xml10_s_rx\z/ /o;
	} elsif($trailing_wsp ne "PRESERVE") {
		_throw_data_error("bad character canonicalisation option");
	}
	return $string;
}

sub xml_s_canonise_chars($$) {
	check_xml_chardata($_[0]);
	return &_canonise_chars;
}

*xs_charcanon = \&xml_s_canonise_chars;

=item xml_c_canonise_chars(CONTENT, OPTIONS)

=item xc_charcanon(CONTENT, OPTIONS)

This function is intended to help in parsing XML data, in situations
where the schema states that some aspects of characters are not
entirely significant.  I<CONTENT> must be a reference to either an
L<XML::Easy::Content> object or a twine array.  The function processes its
top-level character content in the same way as L</xml_s_canonise_chars>,
and returns the resulting modified version of the content in the same
form that the input supplied.

Any element inside the content chunk acts like a special character that
will not be modified.  It interrupts any character sequence of interest.
Elements are not processed recursively: they are treated as atomic.

=cut

sub _canonise_chars_twine($$) {
	my($twine, $options) = @_;
	return [ _canonise_chars($twine->[0], $options) ]
		if @$twine == 1;
	my $leading_options = {%$options};
	my $intermediate_options = {%$options};
	my $trailing_options = {%$options};
	$leading_options->{trailing_wsp} =
		$intermediate_options->{leading_wsp} =
		$intermediate_options->{trailing_wsp} =
		$trailing_options->{leading_wsp} =
			exists($options->{intermediate_wsp}) ?
				$options->{intermediate_wsp} : "PRESERVE";
	my @output = @$twine;
	$output[0] = _canonise_chars($output[0], $leading_options);
	$output[-1] = _canonise_chars($output[-1], $trailing_options);
	for(my $i = @output - 3; $i != 0; $i--) {
		$output[$i] =
			_canonise_chars($output[$i], $intermediate_options);
	}
	return \@output;
}

sub xml_c_canonise_chars($$) {
	if(is_ref($_[0], "ARRAY")) {
		check_xml_content_twine($_[0]);
		return xml_content_twine(&_canonise_chars_twine);
	} else {
		return xml_content_object(_canonise_chars_twine(
			xml_c_content_twine($_[0]), $_[1]));
	}
}

*xc_charcanon = \&xml_c_canonise_chars;

=item xml_c_subelements(CONTENT, ALLOW_WSP)

=item xc_subelems(CONTENT, ALLOW_WSP)

This function is intended to help in parsing XML data, in situations
where the schema calls for an element to contain only subelements,
possibly with optional whitespace around and between them.

I<CONTENT> must be a reference to either an L<XML::Easy::Content> object
or a twine array.  The function checks whether the content includes
any unpermitted characters at the top level, and C<die>s if it does.
If the content is of permitted form, the function returns a reference
to an array listing all the subelements.

I<ALLOW_WSP> is a truth value controlling whether whitespace is permitted
around and between the subelements.  The characters recognised as
whitespace are the same as those for XML syntax.  Allowing whitespace in
this way is easier (and slightly more efficient) than first filtering
it out via L</xml_c_canonise_chars>.  Non-whitespace characters are
never permitted.

=cut

sub xml_c_subelements($$) {
	my($content, $allow_wsp) = @_;
	$content = xml_c_content_twine($content);
	my $clen = @$content;
	for(my $i = $clen-1; $i >= 0; $i -= 2) {
		if($allow_wsp) {
			_throw_schema_error("non-whitespace characters ".
						"where not permitted")
				unless $content->[$i] =~ /\A$xml10_s_rx?\z/o;
		} else {
			_throw_schema_error("characters where not permitted")
				unless $content->[$i] eq "";
		}
	}
	my @subelem;
	for(my $i = 1; $i < $clen; $i += 2) {
		push @subelem, $content->[$i];
	}
	return \@subelem;
}

*xc_subelems = \&xml_c_subelements;

=item xml_c_chardata(CONTENT)

=item xc_chars(CONTENT)

This function is intended to help in parsing XML data, in situations
where the schema calls for an element to contain only character data.
I<CONTENT> must be a reference to either an L<XML::Easy::Content> object
or a twine array.  The function C<die>s if it contains any subelements.
If the content is of permitted form, the function returns a string
containing all the character content.

=cut

sub xml_c_chardata($) {
	my($content) = @_;
	$content = xml_c_content_twine($content);
	_throw_schema_error("subelement where not permitted")
		unless @$content == 1;
	return $content->[0];
}

*xc_chars = \&xml_c_chardata;

=back

=head1 SEE ALSO

L<XML::Easy::NodeBasics>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2010 PhotoBox Ltd

Copyright (C) 2011 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
