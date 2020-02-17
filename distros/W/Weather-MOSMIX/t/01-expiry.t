#!perl
use strict;
use warnings;
use Test::More tests => 2;

use Weather::MOSMIX::Reader;

{
package Test::Weather::MOSMIX::Writer;
    sub start {};
    sub commit {};
}

my $w = bless {} => 'Test::Weather::MOSMIX::Writer';

my $r = Weather::MOSMIX::Reader->new(
    writer => $w,
);

open my $xml,'<', \<<XML;
<?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>
<kml:kml xmlns:dwd="https://opendata.dwd.de/weather/lib/pointforecast_dwd_extension_V1_0.xsd" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:xal="urn:oasis:names:tc:ciq:xsdschema:xAL:2.0" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
    <kml:Document>
        <kml:ExtendedData>
            <dwd:ProductDefinition>
                <dwd:Issuer>Deutscher Wetterdienst</dwd:Issuer>
                <dwd:ProductID>MOSMIX</dwd:ProductID>
                <dwd:GeneratingProcess>DWD MOSMIX hourly, Version 1.0</dwd:GeneratingProcess>
                <dwd:IssueTime>2019-06-22T08:00:00.000Z</dwd:IssueTime>
                <dwd:ReferencedModel>
                    <dwd:Model dwd:name="ICON" dwd:referenceTime="2019-06-22T00:00:00Z"/>
                    <dwd:Model dwd:name="ECMWF/IFS" dwd:referenceTime="2019-06-21T12:00:00Z"/>
                </dwd:ReferencedModel>
            </dwd:ProductDefinition>
        </kml:ExtendedData>
    </kml:Document>
</kml:kml>
XML

$r->parse_fh($xml);
is $r->expiry, '2019-06-23T08:00:00Z', "We parse the expiry from the XML";

seek $xml, 0,0;

$r->parse_fh($xml, 'foo');
is $r->expiry, '2019-06-23T08:00:00Z', "We parse the expiry from the XML even if it's given elsewhere";
