#!perl -T

use strict;
use warnings;
use Test::Deep;
use Test::NoWarnings;

use Test::XML::Deep tests => 2;

{
    my $xml = <<EOXML;
<?xml version="1.0" encoding="UTF-8"?>
<example>
    <sometag attribute="value">some data</sometag>
</example>
EOXML

    my $expected = { 'sometag' => {
                                     attribute => 'value',
                                     content   => 'some data'
                                   },
                   };

    cmp_xml_deeply($xml, $expected);
}




