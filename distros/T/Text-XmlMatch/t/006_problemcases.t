# -*- perl -*-

# t/006_problemcases.t - check module ability to determine split-merge groups 

use Test::More tests => 7;
use Data::Dumper;

BEGIN { use_ok( 'Text::XmlMatch' ); }
use Text::XmlMatch;

my $results;
my $keyCount;

my $matcher = Text::XmlMatch->new('extras/EHConfig.xml');

# ASD Exception block
$results = $matcher->findMatch('03599-1751-1-a-t.asd.ph-RH');
if ($results->{'Nashville-RDC_SERVICE-asd'} eq 'datacenter') {
  pass('Nashville-RDC_SERVICE-asd Detection');
} else {
  fail('Nashville-RDC_SERVICE-asd Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for ASD');
} else {
  fail("Unique matches for ASD - $keyCount");
}

# MSO Exception Block
$results = $matcher->findMatch('msod870-1750-1-p-h.mso.na-RH');
if ($results->{'Nashville-RDC_SERVICE-mso'} eq 'datacenter') {
  pass('MSO Detection');
} else {
  fail('MSO Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for MSO');
} else {
  fail("Unique matches for MSO - $keyCount");
}

#DisasterDC/Disaster Recovery
$results = $matcher->findMatch('nasun-7204-1-b-d.sun.na-FastEthernet1/0.1-ISLvLANsubif');
if ($results->{'FortWorth-RDC'} eq 'datacenter') {
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

my $facilityMatch = Text::XmlMatch->new('extras/facilityConfig.xml');
#Uncomment the following when the defect has been corrected regarding
#what happens when a pattern name is declared twice.  May not be helped..
#
#nandc-2811-2-v-h.ndc.na.testdomain.com missed filters
#$results = $facilityMatch->findMatch('nandc-2811-2-v-h.ndc.na.testdomain.com');
#print "Dump:" . Dumper($results);
#if ($results->{'RDC-Nashville'} eq 'facility') {
#  pass('nandc Detection');
#} else {
#  fail('nandc Detection');
#}
#for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
#if ($keyCount == 1) {
#  pass('Unique matches for nandc');
#} else {
#  fail("Unique matches for nandc - $keyCount");
#}
