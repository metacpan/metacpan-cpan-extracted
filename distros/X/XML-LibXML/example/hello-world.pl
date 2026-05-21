#!/usr/bin/perl

=head1 ABOUT

Minimal example of creating an HTML document using XML::LibXML's DOM
routines, without any subroutines.  Outputs a single line of content:
"Hello world....您好。"

Written to resolve L<https://github.com/cpan-authors/XML-LibXML/issues/66>.

=cut

use strict;
use warnings;

use XML::LibXML;

my $doc  = XML::LibXML->createDocument;
my $html = $doc->createElement('html');
my $body = $doc->createElement('body');
my $p    = $doc->createElement('p');

$p->appendText("Hello world....您好。");
$body->appendChild($p);
$html->appendChild($body);
$doc->setDocumentElement($html);
$doc->createInternalSubset( "html", (undef) x 2 );

print $doc->toStringHTML();
