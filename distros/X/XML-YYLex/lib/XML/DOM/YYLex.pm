#!/usr/local/bin/perl -w
##
##  YYLex.pm
##
##  Daniel Bößwetter, Mon Nov 18 11:42:40 CET 2002
##  boesswetter@peppermind.de
##
##  $Log: YYLex.pm,v $
##  Revision 1.2  2003/01/11 00:50:19  daniel
##  Oops, forgor versions numbers for CPAN compatibility and added homepage url
##  in several places (all PODs and README)
##
##  Revision 1.1.1.1  2002/11/24 17:18:15  daniel
##  initial checkin
##
##

package XML::DOM::YYLex;
our $VERSION = '0.01';
use strict;
use XML::YYLex;
use vars qw(@ISA);
@ISA = qw(XML::YYLex);
use XML::DOM;

sub _xml_getDocumentElement {
    my $self = shift;
    return shift->getDocumentElement
}

sub _xml_isTextNode {
    my $self = shift;
    my $node = shift;
    return $node->getNodeType == TEXT_NODE;
}

sub _xml_isElementNode {
    my $self = shift;
    my $node = shift;
    return $node->getNodeType == ELEMENT_NODE;
}

sub _xml_isDocumentNode {
    my $self = shift;
    my $node = shift;
    return $node->getNodeType == DOCUMENT_NODE;
}

1;

=pod

=head1 NAME

XML::DOM::YYLex - XML::DOM-specific part of C<XML::YYLex>

=head1 SYNOPSIS

  use XML::YYLex;
  my $parser = XML::YYLex::create_object( $xml_dom_reference );

=head1 DESCRIPTION

This module implements the parts of C<XML::YYLex> that are specific to
the XML::DOM module. Rather than interacting with this module directly
you create instances of it through the factory method C<create_object>
defined in C<XML::YYLex>.

Please read the C<XML::YYLex> manpage for further info.

=head1 SEE ALSO

L<XML::YYLex>, L<XML::Sablotron::YYLex>, L<XML::DOM>

The XML-YYLex homepage: http://home.debitel.net/user/boesswetter/xml_yylex/

=cut
