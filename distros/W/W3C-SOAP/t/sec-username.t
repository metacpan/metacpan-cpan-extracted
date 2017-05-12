#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use W3C::SOAP::Header::Security::Username;
use XML::LibXML;
BEGIN {
    eval { require Test::XML };
    if ($@) {
        plan(skip_all => "Can't run with out Test::XML");
    }
    Test::XML->import;
};

xml();
done_testing();

sub xml {
    my $su = W3C::SOAP::Header::Security::Username->new(
        username => 'uname',
        password => 'secure',
    );
    my $xml = XML::LibXML->load_xml(string => <<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Header/>
    <soapenv:Body/>
</soapenv:Envelope>
XML
    my $sec = $su->to_xml($xml);
    like($sec->toString, qr{<wsse:Username>uname</wsse:Username>}, 'Security header generated correctly')
        or note $sec->toString;
}
