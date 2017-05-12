#!/usr/bin/perl -w

use Test::More no_plan;
use strict;
use warnings;
use XML::Compare;
use MooseX::TimestampTZ;
BEGIN { use_ok("XML::SRS") }

my $one = XML::SRS::Result->new(
	action => "GetMessages",
	fe_id => "1",
	unique_id => "12345",
	by_id => "100",
	rows => 2,
	server_time => "2010-07-01 12:00:00+0900", # FIXME: fiddly
	response => XML::SRS::Domain->new( name => "foo.co.te" ),
);
ok($one, "create Result: simple");

my $rs = XML::SRS::Response->new(
	results => [$one],
	version => "auto",
);
ok($rs, "create Response with version => auto");
my $xml_request = $rs->to_xml;

my $xmlc = XML::Compare->new();

my $XML = <<XML;
<NZSRSResponse VerMinor="0" VerMajor="5">
  <Response Rows="2" FeSeq="12345" FeId="1" Action="GetMessages" OrigRegistrarId="100">
    <FeTimeStamp Year="2010" Month="07" Hour="12" TimeZoneOffset="+0900" Day="01" Second="00" Minute="00" />
    <Domain DomainName="foo.co.te" />
  </Response>
</NZSRSResponse>
XML

ok($xmlc->is_same( $xml_request, $XML ), "Result: simple")
	or diag("Error: ".$xmlc->error);

eval { $one->responses };
is($@, '', "asking for responses from a single-part response OK");

my $multi = XML::SRS::Result->new(
	action => "GetMessages",
	fe_id => "1",
	unique_id => "12345",
	by_id => "100",
	rows => 2,
	server_time => "2010-07-01 12:00:00Z",
	responses => [
		XML::SRS::Domain->new( name => "foo.co.te" ),
		XML::SRS::Domain->new( name => "bar.co.te" ),
	],
);
ok($multi, "create Result: multi");

$rs = XML::SRS::Response->new(
	results => [$multi],
	version => "auto",
);
$xml_request = $rs->to_xml;

$xmlc = XML::Compare->new();

$XML = <<XML;
<NZSRSResponse VerMinor="0" VerMajor="5">
  <Response Rows="2" FeSeq="12345" FeId="1" Action="GetMessages" OrigRegistrarId="100">
    <FeTimeStamp Year="2010" Month="07" Hour="12" TimeZoneOffset="+00:00" Day="01" Second="00" Minute="00" />
    <Domain DomainName="foo.co.te" />
    <Domain DomainName="bar.co.te" />
  </Response>
</NZSRSResponse>
XML

ok($xmlc->is_same( $xml_request, $XML ), "Result: multi")
	or diag("Error: ".$xmlc->error);

eval { $multi->response };
ok($@, "asking for response from a multi-part response fails");
