# -*- perl -*-

#this tests the module's ability to handle a configuration that only
#contains a single pattern.

use Test::More tests => 2;
use Data::Dumper;

BEGIN { use Text::XmlMatch; }
use Text::XmlMatch;

my $matcher = Text::XmlMatch->new('extras/singlepattern.xml');

$results = $matcher->findMatch('corp-test-dummydevice.medcity.net');
#print Dumper($results);
if ($results->{'DATACENTER-ndc'} eq 'market') {
  pass('findMatch() w/Single Pattern XML Configuration');
} else {
  fail("findMatch() w/Single Pattern XML Configuration Dumper($results)");
}

$results = $matcher->listGroups();
if (scalar(@$results) == 1) {
  pass('listGroups() w/Single Pattern XML Configuration');
} else {
  print Dumper($results);
  fail('listGroups() w/Single Pattern XML Configuration');
}
