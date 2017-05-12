use strict;
use warnings;

use Test::More tests => 5;                      # last test to print

use XML::XPathScript;

my $xps = XML::XPathScript->new( stylesheet => '<%~ / %>' );

# a string
$xps->set_xml( '<string />' );
is $xps->transform, '<string></string>';

# a file
$xps->set_xml( 't/t1.xml' );
is $xps->transform, 
    '<doc><chicken><egg>Pok</egg></chicken><turkey></turkey><ostrich>gloo?</ostrich></doc>';

my $doc = $XML::XPathScript::XML_parser eq 'XML::LibXML'
        ? XML::LibXML->new->parse_string( '<outer><inner/></outer>' )
        : XML::XPath->new( xml => '<outer><inner/></outer>' )
        ;

# a doc
$xps->set_xml( $doc );
is $xps->transform, '<outer><inner></inner></outer>';

# an element
$xps->set_xml( $doc->findnodes( '/outer/inner' ) );
is $xps->transform, '<inner></inner>';

# a fh
open my $fh, '<', 't/t1.xml';
$xps->set_xml( $fh );
is $xps->transform, 
    '<doc><chicken><egg>Pok</egg></chicken><turkey></turkey><ostrich>gloo?</ostrich></doc>';

