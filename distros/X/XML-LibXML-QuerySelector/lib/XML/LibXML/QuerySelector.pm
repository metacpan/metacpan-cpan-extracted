use 5.008;
use strict;
use utf8;

package XML::LibXML::QuerySelector;

use HTML::Selector::XPath 0.13 qw//;
use XML::LibXML 1.70 qw//;

BEGIN
{
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.005';
	
	push @XML::LibXML::Document::ISA, __PACKAGE__;
	push @XML::LibXML::DocumentFragment::ISA, __PACKAGE__;
	push @XML::LibXML::Element::ISA, __PACKAGE__;
}

my $contains = sub 
{
	my $self = shift;
	my ($node) = @_;
	my $self_path = $self->nodePath;
	my $node_path = $node->nodePath;
	my $sub_node_path = substr $node_path, 0, length $self_path;
	$sub_node_path eq $self_path;
};

sub querySelectorAll
{
	my $self = shift;
	my ($selector_string) = @_;
	my $selector = "HTML::Selector::XPath"->new($selector_string);
	
	my $document = $self->nodeName =~ /^#/ ? $self : $self->ownerDocument;
	my $nsuri    = $document->documentElement->lookupNamespaceURI('');
	
	my $xc = "XML::LibXML::XPathContext"->new($document);
	$xc->registerNs(defaultns => $nsuri) if $nsuri;

	my $xpath = defined $nsuri
		? $selector->to_xpath(prefix => 'defaultns')
		: $selector->to_xpath;

	if ($document == $self)
	{
		return $xc->findnodes($xpath);
	}
	
	my @results = map
		{ $self->$contains($_) ? ($_) : () }
		@{[ $xc->findnodes($xpath) ]};
	
	wantarray ? @results : "XML::LibXML::NodeList"->new(@results);
}

sub querySelector
{
	my $self = shift;
	my ($selector_string) = @_;
	my $results = $self->querySelectorAll($selector_string);
	return unless $results->size;
	$results->shift;
}

__FILE__
__END__

=head1 NAME

XML::LibXML::QuerySelector - add querySelector and querySelectorAll methods to XML::LibXML nodes

=head1 SYNOPSIS

  use XML::LibXML::QuerySelector;
  
  my $document = XML::LibXML->load_xml(location => 'my.xhtml');
  my $warning  = $document->querySelector('p.warning strong');
  print $warning->toString if defined $warning;

=head1 DESCRIPTION

This module defines a class (it has no constructor so perhaps closer to an
abstract class or a role) XML::LibXML::QuerySelector, and sets itself up as
a superclass (not a subclass) of L<XML::LibXML::Document>,
L<XML::LibXML::DocumentFragment> and L<XML::LibXML::Element>, thus making
its methods available to objects of those classes.

Yes, this is effectively monkey-patching, but it's performed in a
I<relatively> safe manner.

=head2 Methods

The methods provided by this module are defined in the W3C Recomendation
"Selectors API Level 1" L<http://www.w3.org/TR/selectors-api/>.

=over

=item C<< querySelector($selector) >>

Given a CSS selector, returns the first match or undef if there are no
matches.

=item C<< querySelectorAll($selector) >>

Given a CSS selector, returns all matches as a list, or if called in scalar
context, as an L<XML::LibXML::NodeList>.

=back

=head1 CAVEATS

=over

=item * When called on an element, C<querySelectorAll> returns a static
node list; not a live node list. (Called on a document or document
fragment, it will return a live node list as specified in the W3C
Recommendation.)

=item * Use on mixed-namespace documents is largely untested. The module
is mostly intended for use with XHTML and HTML documents.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=XML-LibXML-QuerySelector>.

=head1 TODO

=over

=item * Consider adding HTML5 DOM traversal methods including
C<getElementsByClassName>.

=back

=head1 SEE ALSO

L<HTML::Selector::XPath>,
L<XML::LibXML>.

L<http://www.w3.org/TR/selectors-api/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 THANKS

Tatsuhiko Miyagawa and Max Maischein, for L<HTML::Selector::XPath>, and for
resolving L<https://rt.cpan.org/Ticket/Display.html?id=73719> quickly.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

