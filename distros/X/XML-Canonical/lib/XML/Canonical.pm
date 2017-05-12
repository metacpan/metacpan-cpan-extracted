package XML::Canonical;

use strict;
use warnings;

use vars qw($VERSION @ISA);

$VERSION = '0.10';

use XML::GDOME;

require DynaLoader;
require Exporter;
@ISA = qw(DynaLoader Exporter);

bootstrap XML::Canonical $VERSION;

sub new {
  my ($class, %opt) = @_;
  my $comments = (exists $opt{comments} && $opt{comments}) ? 1 : 0;
  my $self = bless { comments => $comments }, $class;
  return $self;
}

sub canonicalize_string {
  my ($self, $string) = @_;
  my $doc = XML::GDOME->createDocFromString($string, GDOME_LOAD_SUBSTITUTE_ENTITIES | GDOME_LOAD_COMPLETE_ATTRS);
  $string = $self->canonicalize_document($doc);
  return $string;
}

sub canonicalize_document {
  my ($self, $doc, $xpath) = @_;
  _canonicalize_document($doc, 0, $self->{comments}, $xpath);
}

sub canonicalize_nodes {
  my ($self, $doc, $nodes) = @_;
}

1;
__END__

=head1 NAME

XML::Canonical - Perl Implementation of Canonical XML

=head1 SYNOPSIS

  use XML::Canonical;
  $canon = XML::Canonical->new(comments => 1);
  $canon_xml = $canon->canonicalize_string($xml_string);
  $canon_xml = $canon->canonicalize_document($xmlgdome_document);

  my @nodes = $doc->findnodes(qq{(//*[local-name()='included'] | //@*)});
  my $canon_output = $canon->canonicalize_nodes($doc, \@nodes);

=head1 DESCRIPTION

This module provides an implementation of Canonical XML Recommendation
(Version 1, 15 March 2001).  It uses L<XML::GDOME> for its DOM tree and
XPath nodes.

It provides a XS wrapper around libxml2's Canonical XML code.

=head1 METHODS

=over 4

=item $canon = XML::Canonical->new( comments => $comments );

Returns a new XML::Canonical object.  If $comments is 1, then the
canonical output will include comments, otherwise comments will be
removed from the output.

=item $output = $canon->canonicalize_string( $xml_string );

Reads in an XML string and outputs its canonical form.

=item $output = $canon->canonicalize_document( $libxml_doc, $xpath_res );

Reads in a XML::LibXML::Document object and returns its canonical form.

The optional C<$xpath_res> specifics a set of visible nodes
in terms of a XPath query result.

=back

=head1 TODO

Support for XML Signature and upcoming XML Encryption.  Probably as
an XS wrapper to XMLSec Library, see
http://www.aleksey.com/xmlsec/

Support XML::LibXML as well as XML::GDOME.

=head1 NOTES

This module is in early alpha stage.  It is suggested that you look over
the source code and test cases before using the module.  In addition,
the API is subject to change.

This module implements the lastest w3 recommendation, located at
http://www.w3.org/TR/2001/REC-xml-c14n-20010315

Comments, suggestions, and patches welcome.

=head1 AUTHOR

T.J. Mather, E<lt>tjmather@tjmather.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2002 T.J. Mather.  XML::Canonical is free software;
you may redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::GDOME>, L<XML::Handler::CanonXMLWriter>.

=cut
