package WebService::Cmis::Test::ObjectType;
use base qw(WebService::Cmis::Test);
use Test::More;

use strict;
use warnings;

use Error qw(:try);

sub test_ObjectType : Tests {
  my $this = shift;

  my $repo = $this->getRepository;

  my $typeDefs = $repo->getTypeDefinitions;
  isa_ok($typeDefs, 'WebService::Cmis::AtomFeed::ObjectTypes');

  my $size = $typeDefs->getSize;
  note("found $size type definitions");

  $this->num_tests($size*18+1);

  while (my $objectType = $typeDefs->getNext) {
    isa_ok($objectType, 'WebService::Cmis::ObjectType');

    note("attributes=".join(", ", keys %{$objectType->getAttributes}));

    my $id = $objectType->getId;
    my $displayName = $objectType->getDisplayName;
    my $description = $objectType->getDescription;
    my $link = $objectType->getLink;
    my $baseId = $objectType->getBaseId;
    my $localName = $objectType->getLocalName;
    my $localNamespace = $objectType->getLocalNamespace;
    my $queryName = $objectType->getQueryName;
    my $contentStreamAllowed = $objectType->getContentStreamAllowed || '';

    my $isCreatable = $objectType->isCreatable;
    my $isFileable = $objectType->isFileable;
    my $isQueryable = $objectType->isQueryable;
    my $isFulltextIndexed = $objectType->isFulltextIndexed;
    my $isIncludedInSupertypeQuery = $objectType->isIncludedInSupertypeQuery;
    my $isControllablePolicy = $objectType->isControllablePolicy;
    my $isControllableACL = $objectType->isControllableACL;
    my $isVersionable = $objectType->isVersionable;

    note("id=$id ($objectType->{attributes}{id}");
    note("  displayName=$displayName");
    note("  description=$description");
    note("  link=$link");
    note("  baseId=$baseId");
    note("  localName=$localName");
    note("  localNamespace=$localNamespace");
    note("  queryName=$queryName");
    note("  contentStreamAllowed=$contentStreamAllowed");
 
    note("  isCreatable=$isCreatable");
    note("  isFileable=$isFileable");
    note("  isQueryable=$isQueryable");
    note("  isFulltextIndexed=$isFulltextIndexed");
    note("  isIncludedInSupertypeQuery=$isIncludedInSupertypeQuery");
    note("  isControllablePolicy=$isControllablePolicy");
    note("  isControllableACL=$isControllableACL");
    note("  isVersionable=$isVersionable");

    $objectType->reload;
    note("2 - id=".$objectType->getId.", displayName=".$objectType->getDisplayName.", description=".$objectType->getDescription.", link=".$objectType->getLink);

    is($id, $objectType->getId);
    is($displayName, $objectType->getDisplayName);
    is($description, $objectType->getDescription);
    is($link, $objectType->getLink);
    is($baseId, $objectType->getBaseId);
    is($localName, $objectType->getLocalName);
    is($localNamespace, $objectType->getLocalNamespace);
    is($queryName, $objectType->getQueryName);
    is($contentStreamAllowed, ($objectType->getContentStreamAllowed||''));

    is($isCreatable, $objectType->isCreatable);
    is($isFileable, $objectType->isFileable);
    is($isQueryable, $objectType->isQueryable);
    is($isFulltextIndexed, $objectType->isFulltextIndexed);
    is($isIncludedInSupertypeQuery, $objectType->isIncludedInSupertypeQuery);
    is($isControllablePolicy, $objectType->isControllablePolicy);
    is($isControllableACL, $objectType->isControllableACL);
    is($isVersionable, $objectType->isVersionable);
  }
}


1;
