package WebService::Cmis::Test::ACL;
use base qw(WebService::Cmis::Test);

use strict;
use warnings;

use Test::More;
use Error qw(:try);
use WebService::Cmis qw(:collections :utils :relations :namespaces :contenttypes);
use WebService::Cmis::ACL;

use XML::LibXML qw(:libxml);

sub test_ACL_getXmlDoc : Test {
  my $this = shift;

  # SMELL: there might be either separate cmis:permission paragraphs for the
  # same principal, or just one with all permissions listed within.
  my $origString = <<'HERE';
<?xml version="1.0" encoding="UTF-8"?>
<acl xmlns="http://docs.oasis-open.org/ns/cmis/core/200908/">
  <permission>
    <principal>
      <principalId>jdoe</principalId>
    </principal>
    <direct>false</direct>
    <permission>cmis:read</permission>
  </permission>
  <permission>
    <principal>
      <principalId>jdoe</principalId>
    </principal>
    <direct>false</direct>
    <permission>cmis:write</permission>
  </permission>
</acl>
HERE

  my $xmlDoc = XML::LibXML->load_xml(string => $origString);

  my $acl = new WebService::Cmis::ACL(xmlDoc=>$xmlDoc);
  my $newString = $acl->getXmlDoc->toString(1);

  #note("orig:\n$origString");
  note("new:\n$newString\n");

  is($newString, $origString) or $this->reportXmlDiff($newString, $origString);
}

sub test_ACL_empty : Test(4) {
  my $this = shift;

  my $acl = new WebService::Cmis::ACL();
  ok(defined $acl);
  isa_ok($acl, 'WebService::Cmis::ACL');

  is($acl->getSize, 0);
  ok(!defined $acl->{xmlDoc});
}

sub test_ACL_addEntry_separate : Test(3) {
  my $this = shift;

  my $writeAccess = new WebService::Cmis::ACE(
    principalId => 'jdoe',
    direct => 'true',
    permissions => 'cmis:write'
  );

  my $readAccess = new WebService::Cmis::ACE(
    principalId => 'jdoe',
    direct => 'true',
    permissions => 'cmis:read'
  );

  my $acl = new WebService::Cmis::ACL();

  $acl->addEntry($writeAccess);
  $acl->addEntry($readAccess);
  is($acl->getSize, 2);

  my $string = $acl->getXmlDoc->toString(1);
  ok(defined $string);

  my $expected = <<'HERE';
<?xml version="1.0" encoding="UTF-8"?>
<acl xmlns="http://docs.oasis-open.org/ns/cmis/core/200908/">
  <permission>
    <principal>
      <principalId>jdoe</principalId>
    </principal>
    <direct>true</direct>
    <permission>cmis:write</permission>
  </permission>
  <permission>
    <principal>
      <principalId>jdoe</principalId>
    </principal>
    <direct>true</direct>
    <permission>cmis:read</permission>
  </permission>
</acl>
HERE

  is($string, $expected) or $this->reportXmlDiff($string, $expected)
}

sub test_ACL_addEntry_joined : Test(3) {
  my $this = shift;

  my $ace = new WebService::Cmis::ACE(
    principalId => 'jdoe',
    direct => 'true',
    permissions => ['cmis:write', 'cmis:read']
  );

  my $acl = new WebService::Cmis::ACL();
  $acl->addEntry($ace);
  is($acl->getSize, 1);

  my $string = $acl->getXmlDoc->toString(1);
  ok(defined $string);

  my $expected = <<'HERE';
<?xml version="1.0" encoding="UTF-8"?>
<acl xmlns="http://docs.oasis-open.org/ns/cmis/core/200908/">
  <permission>
    <principal>
      <principalId>jdoe</principalId>
    </principal>
    <direct>true</direct>
    <permission>cmis:write</permission>
    <permission>cmis:read</permission>
  </permission>
</acl>
HERE

  is($string, $expected) or $this->reportXmlDiff($string, $expected)
}

sub test_ACL_addEntry_chained : Tests {
  my $this = shift;

  my $acl = new WebService::Cmis::ACL()->addEntry(
    new WebService::Cmis::ACE(
      principalId => 'jdoe',
      direct => 'true',
      permissions => ['cmis:write', 'cmis:read']
    )
  );

  my $string = $acl->getXmlDoc->toString(1);
  ok(defined $string);

  my $expected = <<'HERE';
<?xml version="1.0" encoding="UTF-8"?>
<acl xmlns="http://docs.oasis-open.org/ns/cmis/core/200908/">
  <permission>
    <principal>
      <principalId>jdoe</principalId>
    </principal>
    <direct>true</direct>
    <permission>cmis:write</permission>
    <permission>cmis:read</permission>
  </permission>
</acl>
HERE

  is($string, $expected) or $this->reportXmlDiff($string, $expected)
}

sub test_ACL_removeEntry : Test(5) {
  my $this = shift;

  my $writeAccess = new WebService::Cmis::ACE(
    principalId => 'jdoe',
    direct => 'true',
    permissions => 'cmis:write'
  );

  my $readAccess = new WebService::Cmis::ACE(
    principalId => 'jdoe',
    direct => 'true',
    permissions => 'cmis:read'
  );

  my $acl = new WebService::Cmis::ACL();

  $acl->addEntry($writeAccess);
  note("1: acl=\n".$acl->toString);
  is($acl->getSize, 1);

  $acl->addEntry($readAccess);
  note("2: acl=\n".$acl->toString);
  is($acl->getSize, 2);

  $acl->removeEntry($writeAccess);
  note("3:acl=\n".$acl->toString);
  is($acl->getSize, 1);

  $acl->addEntry($writeAccess);
  is($acl->getSize, 2);

  $acl->removeEntry("jdoe");
  is($acl->getSize, 0);
}

1;
