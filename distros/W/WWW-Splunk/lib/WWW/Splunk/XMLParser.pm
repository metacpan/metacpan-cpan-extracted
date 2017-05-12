=encoding utf8

=head1 NAME

WWW::Splunk::XMLParser - Parse Splunk XML format

=head1 DESCRIPTION

This is an utility module to deal with XML format ocassionally returned
by Splunk and seemlingly undocumented.

Note that Splunk usually returns Atom XMLs, which have the same
content type. They can be distinguished by a DOCTYPE.

=cut

package WWW::Splunk::XMLParser;

use strict;
use warnings;

use XML::LibXML qw/:libxml/;
use Carp;

our $VERSION = '2.06';

=head2 B<parse> (F<string>)

Return a perl structure from a XML string, if it's
parsable, otherwise return a raw XML::LibXML object

=cut
sub parse
{
	my $xml = shift;

	my @tree = eval { parsetree ($xml) };
	return $xml if $@;
	return $#tree ? @tree : $tree[0];
}

=head2 B<parsetree> (F<XML::LibXML::Node>)

Parse a XML node tree recursively.

=cut
sub parsetree
{
	my $xml = shift;
	my @retval;

	my $has_elements = grep { $_->nodeType eq XML_ELEMENT_NODE }
		$xml->nonBlankChildNodes ();

	foreach my $node ($xml->nonBlankChildNodes ()) {

		# Not interested in anything but elements
		next if $has_elements and $node->nodeType ne XML_ELEMENT_NODE;

		# Structure or structure wrapped in Atom
		if ($node->nodeName () eq 'list' or
			$node->nodeName () eq 's:list') {
			push @retval, [ parsetree ($node) ];
		} elsif ($node->nodeName () eq 'dict' or
			$node->nodeName () eq 's:dict') {
			push @retval, { parsetree ($node) };
		} elsif ($node->nodeName () eq 'key' or
			$node->nodeName () eq 's:key') {
			push @retval, $node->getAttribute ('name')
				=> scalar parsetree($node);
		} elsif ($node->nodeName () eq 'response' or
			$node->nodeName () eq 'item' or
			$node->nodeName () eq 's:item') {
			# Basically just ignore these
			push @retval, parsetree ($node);
		} elsif ($node->nodeName () eq 'entry') {
			# Crippled Atom envelope
			foreach my $node ($node->childNodes ()) {
				return parsetree ($node) if $node->nodeName () eq 'content';
			}
		} elsif ($node->nodeType eq XML_TEXT_NODE or $node->nodeName () eq '#cdata-section') {
			return $node->textContent;

		# Results
		} elsif ($node->nodeName () eq 'results') {
			return map { { parsetree ($_) } }
				grep { $_->nodeName eq 'result' }
				$node->childNodes;
		} elsif ($node->nodeName () eq 'field') {
			push @retval, $node->getAttribute ('k')
				=> scalar parsetree($node);
		} elsif ($node->nodeName () eq 'value'
			or $node->nodeName () eq 'v') {
			return $node->textContent;

		# Errors
		} else {
			die "Unknown XML element: ".$node->nodeName
		}
	}

	return wantarray ? @retval : $retval[0];
}

=head1 SEE ALSO

L<WWW::Splunk>, L<WWW::Splunk::API>, L<XML::LibXML>

=head1 AUTHORS

Lubomir Rintel, L<< <lkundrak@v3.sk> >>,
Michal Josef Špaček L<< <skim@cpan.org> >>

The code is hosted on GitHub L<http://github.com/tupinek/perl-WWW-Splunk>.
Bug fixes and feature enhancements are always welcome.

=head1 LICENSE

 This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

1;
