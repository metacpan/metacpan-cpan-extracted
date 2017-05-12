package WebService::Cmis::Test::Object;
use base qw(WebService::Cmis::Test);
use Test::More;

use strict;
use warnings;

use WebService::Cmis qw(:collections :utils :relations :namespaces :contenttypes);
use WebService::Cmis::AtomEntry ();
use WebService::Cmis::Object ();
use WebService::Cmis::Property ();
use WebService::Cmis::Repository ();

sub test_Object_CMIS_XPATH_PROPERTIES : Tests {
  my $this = shift;

  my $xml = $this->getTestXml("object");
  ok(defined $xml);

  my @nodes = $xml->findnodes($WebService::Cmis::Object::CMIS_XPATH_PROPERTIES);
  ok(scalar(@nodes));
  note("found ".scalar(@nodes)." nodes");

  my %props = ();
  foreach my $node (@nodes) {
    my $property = WebService::Cmis::Property::load($node);
    ok(defined $property) || diag("failed to create property from node");
    my $propId = $property->getId;
    ok(defined $propId) || diag("property does not have an id");
    note("property = ".$property->toString);
    ok(!defined $props{$propId}) || diag("duplicate property $propId");
    $props{$propId} = $property;
  }

  ok(defined $props{"cmis:name"} && $props{"cmis:name"}->getValue eq "free.jpg");
  ok(defined $props{"cmis:objectId"});
  ok(defined $props{"cmis:objectTypeId"});
  ok(defined $props{"cmis:isLatestMajorVersion"});
  ok(defined $props{"cmis:contentStreamLength"} && $props{"cmis:contentStreamLength"}->getValue == 63118);
  ok(defined $props{"cmis:contentStreamId"});
  ok(defined $props{"cmis:contentStreamMimeType"} && $props{"cmis:contentStreamMimeType"}->getValue eq "image/jpeg");
  ok(defined $props{"cmis:baseTypeId"} && $props{"cmis:baseTypeId"}->getValue eq "cmis:document");
  ok(defined $props{"cmis:lastModificationDate"});
}

# TODO
# $WebService::Cmis::AtomEntry::CMIS_XPATH_TITLE
# $WebService::Cmis::AtomEntry::CMIS_XPATH_UPDATED
# $WebService::Cmis::AtomEntry::CMIS_XPATH_SUMMARY
# $WebService::Cmis::AtomEntry::CMIS_XPATH_PUBLISHED
# $WebService::Cmis::AtomEntry::CMIS_XPATH_EDITED
# $WebService::Cmis::AtomEntry::CMIS_XPATH_AUTHOR
# $WebService::Cmis::AtomEntry::CMIS_XPATH_ID
# $WebService::Cmis::Repository::CMIS_XPATH_REPOSITORIES

# $WebService::Cmis::ChangeEntry::CMIS_XPATH_PROPERTIES 
# $WebService::Cmis::ChangeEntry::CMIS_XPATH_CHANGETYPE
# $WebService::Cmis::ChangeEntry::CMIS_XPATH_CHANGETIME
# $WebService::Cmis::ChangeEntry::CMIS_XPATH_ACL

1;
