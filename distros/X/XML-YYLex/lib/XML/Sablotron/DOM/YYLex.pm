#!/usr/local/bin/perl -w
##
##  YYLex.pm
##
##  Daniel Bößwetter, Mon Nov 18 11:42:40 CET 2002
##  boesswetter@peppermind.de
##
##  $Log: YYLex.pm,v $
##  Revision 1.3  2003/01/11 00:50:20  daniel
##  Oops, forgor versions numbers for CPAN compatibility and added homepage url
##  in several places (all PODs and README)
##
##  Revision 1.2  2003/01/10 22:30:54  daniel
##  version 0.3 (perl 5.6 and sablot 0.90)
##
##  Revision 1.1.1.1  2002/11/24 17:18:15  daniel
##  initial checkin
##
##

package XML::Sablotron::DOM::YYLex;
our $VERSION = '0.02';
use strict;
use XML::YYLex;
use vars qw(@ISA);
@ISA = qw(XML::YYLex);
use XML::Sablotron::DOM qw(:constants);

sub _xml_getDocumentElement {
    my $self = shift;
    #return shift->documentElement
    ## hm, sablotron 0.90 prefers this (the above line was written for 0.96)
    return shift->getFirstChild;
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

XML::Sablotron::DOM::YYLex - Sablotron-specific part of C<XML::YYLex>

=head1 SYNOPSIS

  use XML::YYLex;
  my $parser = XML::YYLex::create_object( $xml_sablotron_dom_reference );

=head1 DESCRIPTION

This module implements the parts of C<XML::YYLex> that are specific to
the Sablotron module. Rather than interacting with this module directly
you create instances of it through the factory method C<create_object>
defined in C<XML::YYLex>.

Please read the C<XML::YYLex> manpage for further info.

=head1 SEE ALSO

L<XML::YYLex>, L<XML::Sablotron::DOM>, L<XML::DOM::YYLex>

The XML-YYLex homepage: http://home.debitel.net/user/boesswetter/xml_yylex/

=cut
