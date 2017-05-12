# -*- perl -*-

# t/007_listGroups.t - check module ability to list groups defined in the configuration XML file

use Test::More tests => 3;
use Data::Dumper;

BEGIN { use_ok( 'Text::XmlMatch' ); }
use Text::XmlMatch;

my $matcher = Text::XmlMatch->new('extras/EHConfig.xml');

# ASD Exception block
$r_listOfGroups = $matcher->listGroups();
if (@$r_listOfGroups > 10) {
  pass("Group listing reference context");
} else {
  fail("Group listing reference context");
}

#test that an actual array can be returned too
@listOfGroups = $matcher->listGroups();
if (@listOfGroups > 10) {
  pass("Group listing array context");
} else {
  fail("Group listing array context");
}
