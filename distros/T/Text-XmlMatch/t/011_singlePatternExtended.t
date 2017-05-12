# -*- perl -*-

#this tests the module's ability to handle a configuration that only
#contains a single pattern.  This bug was thought fixed, but it was
#discovered that calling listGroups() after a findMatch() was masking
#the problem.  Calling listGroups() by itself reveals this issue.

use Test::More tests => 1;
use Data::Dumper;

BEGIN { use Text::XmlMatch; }
use Text::XmlMatch;

#Now build a list of networks as specified by our grouping mechanism
my $matcher = Text::XmlMatch->new('extras/ConfigurationFile.xml');

my $defined_networks = 0;

eval {
  my @defined_groups = $matcher->listGroups();
};

if ($@) {
  fail("listGroups() w/Single Pattern XML Configuration - Error: $@ ");
} else {
  pass("listGroups() w/Single Pattern XML Configuration");
}
