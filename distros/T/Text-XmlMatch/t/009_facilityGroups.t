# -*- perl -*-

# t/006_problemcases.t - check module ability to determine facility grouping

use Test::More tests => 7;
use Data::Dumper;

BEGIN { use_ok( 'Text::XmlMatch' ); }
use Text::XmlMatch;

my $matcher = Text::XmlMatch->new('extras/facilityConfig.xml');

# ASD Exception block
$results = $matcher->findMatch('03599-1751-1-a-t.asd.ph-RH');
#print Dumper($results);
if ($results->{'COID-03599'} eq 'facility') {
  pass('asd Facility Detection');
} else {
  fail('asd Facility Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for ASD facility');
} else {
  fail("Unique matches for ASD facility - $keyCount");
}

# MSO Exception Block
$results = $matcher->findMatch('msod870-1750-1-p-h.mso.na-RH');
if ($results->{'MSO-870'} eq 'facility') {
  pass('MSO Facility Detection');
} else {
  fail('MSO Facility Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for MSO');
} else {
  fail("Unique matches for MSO - $keyCount");
}

#DisasterDC/Disaster Recovery
$results = $matcher->findMatch('nasun-7204-1-b-d.sun.na-FastEthernet1/0.1-ISLvLANsubif');
#print Dumper($results);
if ($results->{'RDC-DisasterDC'} eq 'facility') {
  pass('DisasterDC/Disaster Recovery Detection');
} else {
  fail('DisasterDC/Disaster Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for DisasterDC/Disaster');
} else {
  fail("Unique matches for DisasterDC/Disaster - $keyCount");
}

