#!/usr/bin/perl -w

use Test::More no_plan;
use strict;
use warnings;
use XML::Compare;
BEGIN { use_ok("XML::SRS") }

my $create = XML::SRS::Domain::Create->new(
	action_id => "kaihoro.co.nz-".1273643528,
	domain_name => "kaihoro.co.nz",
	term => 12,
	delegate => 1,
	contact_registrant => {
		name => "Lord Crumb",
		email => 'kaihoro.takeaways@gmail.com',
		address => {
			address1 => "57 Mount Pleasant St",
			address2 => "Burbia",
			city => "Kaihoro",
			region => "Nelson",
			cc => "NZ",
		},
		phone => {
			cc => "64",
			ndc => "4",
			subscriber => "499 2267",
		},
	},
	nameservers => [qw( ns1.registrar.net.nz ns2.registrar.net.nz )],
);

isa_ok(
	$create, "XML::SRS::Domain::Create",
	"new DomainCreate message"
);

my $xml_request = $create->to_xml;

my $xmlc = XML::Compare->new();

ok($xmlc->is_same( $xml_request, <<'XML' ), "CreateDomain")
<DomainCreate Delegate="1" DomainName="kaihoro.co.nz" Term="12" ActionId="kaihoro.co.nz-1273643528">
  <RegistrantContact Name="Lord Crumb" Email="kaihoro.takeaways@gmail.com">
    <PostalAddress Address2="Burbia" Address1="57 Mount Pleasant St" Province="Nelson" City="Kaihoro" CountryCode="NZ" />
    <Phone LocalNumber="499 2267" AreaCode="4" CountryCode="64" />
  </RegistrantContact>
  <NameServers>
    <Server FQDN="ns1.registrar.net.nz" />
    <Server FQDN="ns2.registrar.net.nz" />
  </NameServers>
</DomainCreate>
XML
	or diag("Error: ".$xmlc->error);
