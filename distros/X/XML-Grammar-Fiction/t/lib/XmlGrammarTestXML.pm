package XmlGrammarTestXML;

use strict;
use warnings;

use parent 'Exporter';

our @EXPORT_OK = (qw(my_is_xml));

use Test::XML::Ordered '0.0.5';
use Test::XML::Ordered qw(is_xml_ordered);

my @is_xml_common = (validation => 0, load_ext_dtd => 0, no_network => 1);

sub my_is_xml
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($got, $expected, $blurb) = @_;

    return is_xml_ordered(
        [ @{$got}, @is_xml_common, ],
        [ @{$expected}, @is_xml_common, ],
        {},
        $blurb,
    );
}

1;

