# -*- perl -*-

use Test::More tests => 7;
use Data::Dumper;

BEGIN { use_ok( 'Text::XmlMatch' ); }
use Text::XmlMatch;

my $matcher = Text::XmlMatch->new('extras/marketConfig.xml');

# ASD Exception block
$results = $matcher->findMatch('03599-1751-1-a-t.asd.ph-RH');
#print Dumper($results);
if ($results->{'SERVICE-asd'} eq 'market') {
  pass('asd Market Detection');
} else {
  fail('asd Market Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for ASD market');
} else {
  fail("Unique matches for ASD market - $keyCount");
}

# MSO Exception Block
$results = $matcher->findMatch('msod870-1750-1-p-h.mso.na-RH');
if ($results->{'SERVICE-mso'} eq 'market') {
  pass('MSO Market Detection');
} else {
  fail('MSO Market Detection');
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
if ($results->{'RDC-sun'} eq 'market') {
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

