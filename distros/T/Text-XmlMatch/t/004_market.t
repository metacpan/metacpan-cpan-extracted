# -*- perl -*-

# t/004_market.t - check module ability to determine market based groups

use Test::More tests => 10;
use Data::Dumper;

BEGIN { use_ok( 'Text::XmlMatch' ); }
use Text::XmlMatch;

my $results;

my $matcher = Text::XmlMatch->new('extras/config.xml');
#'RDC-Nashville' => 'market'
$results = $matcher->findMatch('msod872-1751-1-p-h.mso.na.testdomain.com');

if ($results->{'MARKET-mso'} eq 'market') {
  pass('MSO Market Detection');
} else {
  fail('MSO Market Detection');
}

$results = $matcher->findMatch('corp-b4ef3-2948g-sw03.testdomain.com');
if ($results->{'DATACENTER-ndc'} eq 'market') {
  pass('CORP Devices - Find Market');
} else {
  fail("CORP Devices - Find Market" . Dumper($results));
}

$results = $matcher->findMatch('nandc-7204-2-b-h.ndc.na.testdomain.com');
if ($results->{'DATACENTER-ndc'} eq 'market') {
  pass('CORP Devices - Find Market');
} else {
  fail("CORP Devices - Find Market" . Dumper($results));
}

$results = $matcher->findMatch('fwfdc-1503-1-s-h.fdc.fw.testdomain.com');
if ($results->{'DATACENTER-fdc'} eq 'market') {
  pass('fdc Devices - Find Market');
} else {
  fail("fdc Devices - Find Market");
  print Dumper($results);
}

$results = $matcher->findMatch('msod385-1750-1-p-h.mso.na.testdomain.com');
if ($results->{'MARKET-mso'} eq 'market') {
  pass('MSO Devices without COID - Find Market');
} else {
  fail('MSO Devices without COID - Find Market');
  print Dumper($results);
}

$results = $matcher->findMatch('34234-7204-1-p-h.mso.na.testdomain.com');
if ($results->{'MARKET-mso'} eq 'market') {
  pass('MSO Facility Devices w/COID - Find Market');
} else {
  fail('MSO Facility Devices w/COID - Find Market ' . Dumper($results));
}

$results = $matcher->findMatch('aasd128-3640-1-o-h.aas.na.testdomain.com');
if ($results->{'MARKET-aas'} eq 'market') {
  pass('AAS Devices without COID - Find Market');
} else {
  fail('AAS Devices without COID - Find Market' . Dumper($results));
}

$results = $matcher->findMatch('38973-7204-1-o-h.aas.na.testdomain.com');
if ($results->{'MARKET-aas'} eq 'market') {
  pass('AAS Devices w/COID - Find Market');
} else {
  fail('AAS Devices w/COID - Find Market' . Dumper($results));
}

$results = $matcher->findMatch('cpcscdc-6513-1-m-a.cdc.co.testdomain.com');
if ($results->{'DATACENTER-cdc'} eq 'market') {
  pass('CPCS Devices - Find Market');
} else {
  fail('CPCS Devices - Find Market' . Dumper($results));
}
