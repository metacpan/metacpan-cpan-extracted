# -*- perl -*-

# t/005_market.t - check module ability to determine split-merge groups

use Test::More tests => 43;
use Data::Dumper;

BEGIN { use_ok( 'Text::XmlMatch' ); }
use Text::XmlMatch;

my $results;
my $keyCount;

my $matcher = Text::XmlMatch->new('extras/EHConfig.xml');

# CSC Exception block
$results = $matcher->findMatch('09460-3640-2-s-x.csc.na.testdomain.com');
if ($results->{'Nashville-RDC_SERVICE-csc'} eq 'datacenter') {
  pass('Nashville-RDC_SERVICE-csc Detection');
} else {
  fail('Nashville-RDC_SERVICE-csc Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for CSC');
} else {
  fail("Unique matches for CSC - $keyCount");
}

#NPAS Exception block test
$results = $matcher->findMatch('11813-6509-2-s-x.npa.lo.testdomain.com');
if ($results->{'Nashville-RDC_SERVICE-npa'} eq 'datacenter') {
  pass('Nashville-RDC_SERVICE-npa Detection');
} else {
  fail('Nashville-RDC_SERVICE-npa Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for NPAS');
} else {
  fail("Unique matches for NPAS - $keyCount");
}

#AAS w/o COID Exception block test
$results = $matcher->findMatch('aasd240-3640-1-o-h.aas.na.testdomain.com');
if ($results->{'Nashville-RDC_SERVICE-aas'} eq 'datacenter') {
  pass('Nashville-RDC_SERVICE-aas w/o COID Detection');
} else {
  fail('Nashville-RDC_SERVICE-aas w/o COID Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for aas w/o COID');
} else {
  fail("Unique matches for aas w/o COID - $keyCount");
}

#AAS with COID Exception block test
$results = $matcher->findMatch('38973-7204-2-o-h.aas.na.testdomain.com');
if ($results->{'Nashville-RDC_SERVICE-aas'} eq 'datacenter') {
  pass('Nashville-RDC_SERVICE-aas w/COID Detection');
} else {
  fail('Nashville-RDC_SERVICE-aas w/COID Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for aas w/COID');
} else {
  fail("Unique matches for aas w/COID - $keyCount");
}

#PAS Exception block test
$results = $matcher->findMatch('08591-3550-1-f-x.pas.na.testdomain.com');
if ($results->{'Nashville-RDC_SERVICE-pas'} eq 'datacenter') {
  pass('Nashville-RDC_SERVICE-pas Detection');
} else {
  fail('Nashville-RDC_SERVICE-pas Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for PAS');
} else {
  fail("Unique matches for PAS - $keyCount");
}

#CORP Exception block test
$results = $matcher->findMatch('corp-srv2948gsw03.testdomain.com');
if ($results->{'Nashville-RDC_RDC-corp'} eq 'datacenter') {
  pass('Nashville-RDC_RDC-corp Detection');
} else {
  fail('Nashville-RDC_RDC-corp Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for CORP');
} else {
  fail("Unique matches for CORP - $keyCount");
}

#DisasterDC Exception block test
$results = $matcher->findMatch('nasun-6513-1-b-s.sun.na.testdomain.com');
if ($results->{'Philadelphia-PA-DisasterDC-DRC'} eq 'datacenter') {
  pass('Philadelphia-PA-DisasterDC-DRC Detection');
} else {
  fail('Philadelphia-PA-DisasterDC-DRC Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for DisasterDC');
} else {
  fail("Unique matches for DisasterDC - $keyCount");
}

#Divested Exception block test
$results = $matcher->findMatch('09360-3640-1-f-d.sca.fw.testdomain.com');
if ($results->{'FortWorth-RDC'} eq 'datacenter') {
  pass('Divested Exception Detection');
} else {
  fail('Divested Exception Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for Divested Exception');
} else {
  fail("Unique matches for Divested Exception - $keyCount");
}

#Nashville Datacenter related devices
$results = $matcher->findMatch('05343-3640-2-f-l.tnf.na.testdomain.com');
if ($results->{'Nashville-RDC_MARKET-All'} eq 'datacenter') {
  pass('Nashville Datacenter Region Detection');
} else {
  fail('Nashville Datacenter Region Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for Nashville Datacenter Region');
} else {
  fail("Unique matches for Nashville Datacenter Region - $keyCount");
}

#Devices physcially located in the NDC
$results = $matcher->findMatch('nandc-6509-1-u-h.ndc.na.testdomain.com');
if ($results->{'Nashville-RDC_RDC-ndc'} eq 'datacenter') {
  pass('Nashville Datacenter Device Detection');
} else {
  fail('Nashville Datacenter Device Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for Nashville Datacenter Device');
} else {
  fail("Unique matches for Nashville Datacenter Device - $keyCount");
}


#Orlando Datacenter related devices
$results = $matcher->findMatch('35941-3548-1-f-h.fla.or.testdomain.com');
if ($results->{'Orlando-RDC'} eq 'datacenter') {
  pass('Orlando Datacenter Region Detection');
} else {
  fail('Orlando Datacenter Region Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for Orlando Datacenter Region');
} else {
  fail("Unique matches for Orlando Datacenter Region - $keyCount");
}

#Allen Texas related devices
$results = $matcher->findMatch('atclo-6513-1-u-a.clo.at.testdomain.com');
if ($results->{'Allen-TX-CoLocation-RDC'} eq 'datacenter') {
  pass('Allen, TX Colo Datacenter Region Detection');
} else {
  fail('Allen, TX Colo Region Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for Allen, TX Colo');
} else {
  fail("Unique matches for Allen, TX Colo - $keyCount");
}

#Orlando Florida Colo related devices
$results = $matcher->findMatch('ofclo-7304-1-b-a.clo.of.testdomain.com');
if ($results->{'Orlando-FL-CoLocation-RDC'} eq 'datacenter') {
  pass('Orlando, FL Colo Datacenter Region Detection');
} else {
  fail('Orlando, FL Colo Region Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for Orlando, FL Colo');
} else {
  fail("Unique matches for Orlando, FL Colo - $keyCount");
}

#Phoenix Datacenter related devices
$results = $matcher->findMatch('09373-2811-2-f-h.nva.ph.testdomain.com');
if ($results->{'Phoenix-RDC'} eq 'datacenter') {
  pass('Phoenix Datacenter Region Detection');
} else {
  fail('Phoenix Datacenter Region Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for Phoenix Datacenter Region');
} else {
  fail("Unique matches for Phoenix Datacenter Region - $keyCount");
}

#Columbus Datacenter related devices
$results = $matcher->findMatch('34634-3550-1-f-h.vaa.co.testdomain.com');
if ($results->{'Columbus-RDC'} eq 'datacenter') {
  pass('Columbus Datacenter Region Detection');
} else {
  fail('Columbus Datacenter Region Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for Columbus Datacenter Region');
} else {
  fail("Unique matches for Columbus Datacenter Region - $keyCount");
}

#Alaska Datacenter related devices
$results = $matcher->findMatch('30201-3745-2-e-h.aka.ak.testdomain.com');
if ($results->{'Alaska-RDC'} eq 'datacenter') {
  pass('Alaska Datacenter Region Detection');
} else {
  fail('Alaska Datacenter Region Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for Alaska Datacenter Region');
} else {
  fail("Unique matches for Alaska Datacenter Region - $keyCount");
}

#FortWorth Datacenter related devices
$results = $matcher->findMatch('05604-6506-1-f-t.lah.fw.testdomain.com');
if ($results->{'FortWorth-RDC'} eq 'datacenter') {
  pass('FortWorth Datacenter Region Detection');
} else {
  fail('FortWorth Datacenter Region Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for FortWorth Datacenter Region');
} else {
  fail("Unique matches for FortWorth Datacenter Region - $keyCount");
}

#Louisville Datacenter related devices
$results = $matcher->findMatch('34011-3640-1-f-h.sca.lo.testdomain.com');
if ($results->{'Louisville-RDC'} eq 'datacenter') {
  pass('Louisville Datacenter Region Detection');
} else {
  fail('Louisville Datacenter Region Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for Louisville Datacenter Region');
} else {
  fail("Unique matches for Louisville Datacenter Region - $keyCount");
}

#SanAntonio Datacenter related devices
$results = $matcher->findMatch('06676ma-2811-1-f-h.txi.sa.testdomain.com');
if ($results->{'SanAntonio-RDC'} eq 'datacenter') {
  pass('SanAntonio Datacenter Region Detection');
} else {
  fail('SanAntonio Datacenter Region Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for SanAntonio Datacenter Region');
} else {
  fail("Unique matches for SanAntonio Datacenter Region - $keyCount");
}

#Problem cases
$results = $matcher->findMatch('nandc-7204-1-b-d.ndc.na-RH');
if ($results->{'FortWorth-RDC'} eq 'datacenter') {
  pass('nandc-7204-1-b-d.ndc.na-RH Detection');
} else {
  fail('nandc-7204-1-b-d.ndc.na-RH Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for nandc-7204-1-b-d.ndc.na-RH');
} else {
  fail("Unique matches for nandc-7204-1-b-d.ndc.na-RH - $keyCount");
}

#MSC with COID Exception block test
$results = $matcher->findMatch('08910-3640-1-s-x.msc.na.testdomain.com');
if ($results->{'Nashville-RDC_SERVICE-msc'} eq 'datacenter') {
  pass('Nashville-RDC_SERVICE-msc w/COID Detection');
} else {
  fail('Nashville-RDC_SERVICE-msc w/COID Detection');
}
for ($keyCount=0;$keyCount < (keys %$results); $keyCount++) {}
if ($keyCount == 1) {
  pass('Unique matches for msc w/COID');
} else {
  fail("Unique matches for msc w/COID - $keyCount");
}

