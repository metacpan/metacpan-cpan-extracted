#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use W3C::SOAP::Utils;
use XML::LibXML;

split_ns_test();
normalise_ns_test();
ns2module_test();
cmp_ns_test();
xml_error_test();

done_testing();

sub split_ns_test {
    eval { split_ns() };
    ok $@, "Get an error when called without parameters";
}

sub normalise_ns_test {
}

sub ns2module_test {
    my @url = qw(
        /path/to/intersting.xsd
        file:///path/to/interesting.xsd
        http://www.interesting.com/path/to/interesting.xsd
    );

    for my $url (@url) {
        note my $module = ns2module($url);
    }
}

sub cmp_ns_test {
}

sub xml_error_test {
    my $xml = XML::LibXML->load_xml(string => <<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Body/>
</soapenv:Envelope>
XML
    my $error = xml_error($xml->firstChild);
    is "$error\n", <<'ERROR', 'Show error correctly';
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Body/>
</soapenv:Envelope>
 at path - /soapenv:Envelope
ERROR

    $xml = XML::LibXML->load_xml(string => <<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<thing>
    <error>
        some message
    </error>
</thing>
XML
    $error = xml_error($xml->firstChild->firstChild->nextSibling);
    is "$error\n", <<'ERROR', 'Show error correctly';
    <error>
        some message
    </error>
 at path - /thing/error
ERROR
}
