#!perl
use Test::More;
use strict;
use warnings;

#
# load the module
#
require_ok(q{XML::IETF});

#
# call xmlns() for an unregistered value
#
my $uri = XML::IETF->xmlns('_unregistered');

is($uri, undef);

#
# get the namespace URI for something that is registered
#
$uri = XML::IETF->xmlns('eppcom-1.0');
isa_ok($uri, 'URI::Namespace');

#
# make sure the URI matches what is expected
#
is($uri->as_string, 'urn:ietf:params:xml:ns:eppcom-1.0');

my $url = XML::IETF->schemaLocation($uri);
isa_ok($url, 'URI');

is($url->as_string, 'https://www.iana.org/assignments/xml-registry/schema/eppcom-1.0.xsd');

my $xsd = XML::IETF->xsd($uri);
isa_ok($xsd, 'XML::LibXML::Schema');

my $xsd = XML::IETF->xsd(map { XML::IETF->xmlns($_) } qw(
    eppcom-1.0
    epp-1.0
    domain-1.0
    host-1.0
));

isa_ok($xsd, 'XML::LibXML::Schema');

done_testing;
