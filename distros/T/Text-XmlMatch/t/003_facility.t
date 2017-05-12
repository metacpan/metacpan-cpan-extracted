# -*- perl -*-

# t/003_facility.t - check module ability to handle complex MSO names

use Test::More tests => 13;
use Data::Dumper;

BEGIN { use_ok( 'Text::XmlMatch' ); }
use Text::XmlMatch;

my $results;

my $matcher = Text::XmlMatch->new('extras/config.xml');
#'RDC-Nashville' => 'facility'
$results = $matcher->findMatch('msod872-1751-1-p-h.mso.na.testdomain.com');
if ($results->{'MSO-872'} eq 'facility') {
  pass('MSO Facility Detection');
} else {
  fail('MSO Facility Detection');
}

$results = $matcher->findMatch('corp-b4ef3-2948g-sw03.testdomain.com');
if ($results->{'RDC-Nashville'} eq 'facility') {
  pass('CORP Devices - Find Facility');
} else {
  fail("CORP Devices - Find Facility");
}

$results = $matcher->findMatch('nandc-7204-2-b-h.ndc.na.testdomain.com');
if ($results->{'RDC-Nashville'} eq 'facility') {
  pass('CORP Devices - Find Facility');
} else {
  fail("CORP Devices - Find Facility");
}

$results = $matcher->findMatch('fwfdc-1503-1-s-h.fdc.fw.testdomain.com');
if ($results->{'RDC-FortWorth'} eq 'facility') {
  pass('fdc Devices - Find Facility');
} else {
  fail("fdc Devices - Find Facility");
  print Dumper($results);
}

$results = $matcher->findMatch('msod385-1750-1-p-h.mso.na.testdomain.com');
if ($results->{'MSO-385'} eq 'facility') {
  pass('MSO Devices without COID - Find Facility');
} else {
  fail('MSO Devices without COID - Find Facility');
  print Dumper($results);
}

$results = $matcher->findMatch('34234-7204-1-p-h.mso.na.testdomain.com');
if ($results->{'COID-34234'} eq 'facility') {
  pass('MSO Facility Devices w/COID - Find Facility');
} else {
  fail('MSO Facility Devices w/COID - Find Facility ' . Dumper($results));
}

$results = $matcher->findMatch('aasd128-3640-1-o-h.aas.na.testdomain.com');
if ($results->{'AAS-128'} eq 'facility') {
  pass('AAS Devices without COID - Find Facility');
} else {
  fail('AAS Devices without COID - Find Facility' . Dumper($results));
}

$results = $matcher->findMatch('38973-7204-1-o-h.aas.na.testdomain.com');
if ($results->{'COID-38973'} eq 'facility') {
  pass('AAS Devices w/COID - Find Facility');
} else {
  fail('AAS Devices w/COID - Find Facility' . Dumper($results));
}

$results = $matcher->findMatch('cpcscdc-6513-1-m-a.cdc.co.testdomain.com');
if ($results->{'CPCS-cdc'} eq 'facility') {
  pass('CPCS Devices - Find Facility');
} else {
  fail('CPCS Devices - Find Facility' . Dumper($results));
}

$results = $matcher->findMatch('cpcscdc-6513-1-m-a.cdc.co.testdomain.com');
if ($results->{'CPCS-cdc'} eq 'facility') {
  pass('CPCS Datacenter Devices - Find Facility');
} else {
  fail('CPCS Datacenter Devices - Find Facility' . Dumper($results));
}

$results = $matcher->findMatch('cpcsaka-3550-1-m-h.aka.na.testdomain.com');
if ($results->{'CPCS-aka'} eq 'facility') {
  pass('CPCS Facility Devices - Find Facility');
} else {
  fail('CPCS Facility Devices - Find Facility' . Dumper($results));
}

$results = $matcher->findMatch('nasun-7606-1-b-m.sun.na.testdomain.com');
if ($results->{'RDC-DisasterDC'} eq 'facility') {
  pass('DisasterDC Facility Devices - Find Facility');
} else {
  fail('DisasterDC Facility Devices - Find Facility' . Dumper($results));
}

