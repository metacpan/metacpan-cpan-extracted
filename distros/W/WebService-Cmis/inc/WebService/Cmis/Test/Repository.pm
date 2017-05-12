package WebService::Cmis::Test::Repository;
use base qw(WebService::Cmis::Test);

use strict;
use warnings;

use Error qw(:try);
use Test::More;
use WebService::Cmis qw(:collections :utils :relations :namespaces :contenttypes);

sub test_Repository_getRepositoryName : Test {
  my $this = shift;
  
  my $repo = $this->getRepository;
  my $name = $repo->getRepositoryName;

  note("repository name=$name");
  ok($name);
}

sub test_Repository_getRepositoryId : Test(3) {
  my $this = shift;
  
  my $repo = $this->getRepository;
  my $id1 = $repo->getRepositoryId;

  note("id1=$id1");
  ok($id1);

  my $repo2 = $this->getRepository($id1);
  my $id2 = $repo2->getRepositoryId;
  ok($id2);
  note("id2=$id2");

  is($id1, $id2);
}

sub test_Repository_getRepository_unknown : Test {
  my $this = shift;
  my $client = $this->getClient;
  my $repo = $client->getRepository("foobarbaz");
  ok(!defined $repo);
}

sub test_Repository_getRepositoryInfo : Test(5) {
  my $this = shift;

  my $repo = $this->getRepository;

  my $info = $repo->getRepositoryInfo;

  ok(!defined $info->{capabilities}) or diag("capabilities should not be listed in repository info");
  ok(!defined $info->{aclCapability}) or diag("aclCapabilities should not be listed in repository info");

  note("repositoryInfo :\n".join("\n", map("  ".$_.'='.$info->{$_}, keys %$info)));

  # include
  # SMELL: what's the absolute minimum?
  foreach my $key (qw(repositoryName repositoryId rootFolderId)) {
    note("$key=$info->{$key}");
    ok($info->{$key});
  }
}

sub test_Repository_getCapabilities : Test(28) {
  my $this = shift;

  my $repo = $this->getRepository;

  my $caps = $repo->getCapabilities;

  # no capabilities at all
  SKIP: {
    skip "repository does not support capabilities", 28 unless scalar keys %$caps;

    note("caps:\n".join("\n", map("  ".$_.'='.$caps->{$_}, keys %$caps)));

    foreach my $key (qw( Renditions Multifiling ContentStreamUpdatability Unfiling
      GetFolderTree AllVersionsSearchable Changes Join ACL Query PWCSearchable
      PWCUpdatable VersionSpecificFiling GetDescendants)) {
      my $val = $caps->{"$key"};
      note("$key=$val");
      ok(defined $val) or diag("capability $key not found");
    }
  }
}

sub test_Repository_getSupportedPermissions : Test(1) {
  my $this = shift;

  my $repo = $this->getRepository;
  my $canACL = $repo->getCapabilities()->{'ACL'};
  SKIP: {
    skip "not able to manage ACLs",1 unless $canACL eq 'manage';

    my $perms = $repo->getSupportedPermissions;
    note("perms='$perms'");
    like($perms, qr/^(basic|repository|both)$/);
  }
}

sub test_Repository_getPermissionDefinitions : Tests {
  my $this = shift;

  my $repo = $this->getRepository;
  my $canACL = $repo->getCapabilities()->{'ACL'};
  SKIP: {
    skip "not able to manage ACLs" unless $canACL eq 'manage';

    my $permDefs = $repo->getPermissionDefinitions;
    my $numPermDefs = scalar(keys %$permDefs);
    $this->num_tests($numPermDefs+4);

    ok(defined $permDefs) or diag("no permission definitions found");

    my $foundCmisRead;
    my $foundCmisWrite;
    foreach my $key (keys %$permDefs) {
      #print STDERR "$key = $permDefs->{$key}\n";
      like($key, qr'{http://|cmis:');

      # SMELL: nuxeo calls the basic cmis permissions "basic"... oh well
      $foundCmisRead = 1 if $key =~ /cmis:(read|basic)/;
      $foundCmisWrite = 1 if $key =~ /cmis:(write|basic)/;
    }
    ok(defined $foundCmisRead) or diag("cmis:read not found in permission definition");
    ok(defined $foundCmisWrite) or diag("cmis:write not found in permission definition");
  }
}

sub test_Repository_getPermissionMap : Test(32) {
  my $this = shift;

  my $repo = $this->getRepository;
  my $canACL = $repo->getCapabilities()->{'ACL'};
  SKIP: {
    skip "not able to manage ACLs", 32 unless $canACL eq 'manage';

    my $permMap = $repo->getPermissionMap;
    ok($permMap) or diag("no permission map found");

    note("perms=".join(' ', keys %$permMap));
    my $permMapCount = scalar(keys %$permMap);
    note("found $permMapCount permission mappings");
    foreach my $perm (keys %$permMap) {
      note("$perm=".join(', ', @{$permMap->{$perm}}));
    }

    # SMELL: which of these are standard, which are nice to have?
    my $knownMapCount = 0;
    foreach my $perm (qw(canSetContent.Document canDeleteTree.Folder
      canAddPolicy.Object canAddPolicy.Policy canGetChildren.Folder
      canGetAllVersions.VersionSeries canCancelCheckout.Document canApplyACL.Object
      canMove.Target canGetDescendents.Folder canRemovePolicy.Policy
      canCreateFolder.Folder canGetParents.Folder canGetFolderParent.Object
      canGetAppliedPolicies.Object canUpdateProperties.Object canMove.Object
      canDeleteContent.Document canCheckout.Document canDelete.Object
      canRemoveFromFolder.Object canCreateDocument.Folder canGetProperties.Object
      canAddToFolder.Folder canRemovePolicy.Object canCheckin.Document
      canAddToFolder.Object canGetACL.Object canViewContent.Object)) {
     
      $knownMapCount++;
      note($knownMapCount.": $perm=".join(", ", @{$permMap->{$perm}})); 
      ok($permMap->{$perm}) or diag("permission $perm not defined");
    }
    note("knownMapCount=$knownMapCount");

    is($permMapCount, $knownMapCount);
  }
}

sub test_Repository_getPropagation : Test {
  my $this = shift;

  my $repo = $this->getRepository;
  my $canACL = $repo->getCapabilities()->{'ACL'};
  SKIP: {
    skip "not able to manage ACLs", 1 unless $canACL eq 'manage';

    my $prop = $repo->getPropagation;

    note("prop=$prop");
    like($prop, qr'objectonly|propagate|repositorydetermined');
  }
}

sub test_Repository_getRootFolderId : Test {
  my $this = shift;

  my $repo = $this->getRepository;
  my $rootFolderId = $repo->getRepositoryInfo->{'rootFolderId'};

  note("rootFolderId=$rootFolderId");

  ok($rootFolderId) or diag("no rootFolder found");
}

sub test_Repository_getUriTemplates : Test(4) {
  my $this = shift;

  my $repo = $this->getRepository;

  my $uriTemplates = $repo->getUriTemplates;

  note("types=".join(' ', keys %$uriTemplates));

  foreach my $type (qw(objectbypath query objectbyid typebyid)) {
    ok(defined $uriTemplates->{$type}) or diag("no uri template for $type"); 
    note("type=$type, mediatype=$uriTemplates->{$type}{mediatype}, template=$uriTemplates->{$type}{template}");
  }
}

sub test_Repository_getUriTemplate : Test(4) {
  my $this = shift;

  my $repo = $this->getRepository;

  foreach my $type (qw(objectbypath query objectbyid typebyid)) {
    my $template = $repo->getUriTemplate($type);
    note("template=$template");
    ok(defined $template) or diag("no uri template for $type"); 
  }
}

sub test_Repository_getCollectionLink : Test(8) {
  my $this = shift;

  my $repo = $this->getRepository;

  my $href = $this->{config}{url};
  $href =~ s/^(http:\/\/[^\/]+?):80\//$1\//g; # remove bogus :80 port

  # UNFILED_COLL not supported by all repositories; 
  # SMELL: test for unfiled capability
  foreach my $collectionType (QUERY_COLL, TYPES_COLL, CHECKED_OUT_COLL, ROOT_COLL) {
    my $link = $repo->getCollectionLink($collectionType);
    note("type=$collectionType, link=".($link||''));
    ok(defined $link);
    $link =~ s/^(http:\/\/[^\/]+?):80\//$1\//g; # remove bogus :80 port
    like($link, qr/^$href/);
  }
}

sub test_Repository_getCollection : Tests {
  my $this = shift;

  my $repo = $this->getRepository;

  # QUERY_COLL
  my $error;

  try {
    $repo->getCollection(QUERY_COLL);
  } catch Error::Simple with {
    $error = shift;
    like($error, qr'^query collection not supported');
  };
  ok(defined $error);

  # TYPES_COLL
  my $typeDefs = $repo->getCollection(TYPES_COLL);
  isa_ok($typeDefs, 'WebService::Cmis::AtomFeed::ObjectTypes');
  while (my $typeDef = $typeDefs->getNext) {
    isa_ok($typeDef, 'WebService::Cmis::ObjectType');
    note("typeDef=".$typeDef->toString);
  }

  # other collections
  # SMELL: nuxeo throws a 405 on CHECKED_OUT
  # UNFILED_COLL not allowed for non-admins
  foreach my $collectionType (CHECKED_OUT_COLL, ROOT_COLL) {
    my $result = $repo->getCollection($collectionType);
    note("collectionType=$collectionType, result=$result, nrObjects=".$result->getSize);
    ok(defined $result);
  }
}

sub test_Repository_getTypeDefinition : Test(5) {
  my $this = shift;

  my $repo = $this->getRepository;
  my $objectType = $repo->getTypeDefinition('cmis:folder');
  
  #print "id=".$objectType->getId.", displayName=".$objectType->getDisplayName.", description=".$objectType->getDescription.", link=".$objectType->getLink."\n";

  ok(defined $objectType->getId);
  ok(defined $objectType->getDisplayName);
  ok(defined $objectType->getQueryName);
  ok(defined $objectType->{xmlDoc});

  is($objectType->toString, 'cmis:folder');
}

sub test_Repository_getRootFolder : Test(3) {
  my $this = shift;

  my $repo = $this->getRepository;
  my $obj = $repo->getRootFolder;

  ok(defined $obj) or diag("can't fetch root folder");
  note("obj=".$obj->toString." ($obj)");

  my $props = $obj->getProperties;
  note($props->{"cmis:path"}{displayName}."=".$props->{"cmis:path"}->getValue);
  is("/", $props->{"cmis:path"}->getValue);
  is("", $props->{"cmis:parentId"}->getValue||"");
}

sub test_Repository_getObjectByPath : Test(2) {
  my $this = shift;

  my $repo = $this->getRepository;
  my $root = $repo->getRootFolder;
  my $obj = $repo->getObjectByPath;

  ok(defined $root) or diag("no root folder found");
  note("obj=".$obj->getId.", name=".$obj->getName.", path=".$obj->getPath);

  is($root->getId, $obj->getId);
}

sub test_Repository_getObjectByPath_Sites : Test(2) {
  my $this = shift;
  my $repo = $this->getRepository;

  my $examplePath = $this->{testRoot};
  my $obj = $repo->getObjectByPath($examplePath);

  note("obj=".$obj->getId.", name=".$obj->getName.", path=".$obj->getPath);
  ok(defined $obj) or diag("$examplePath not found");
  is($examplePath, $obj->getPath);
}

sub test_Repository_getObjectByPath_Unknown : Test(3) {
  my $this = shift;
  my $repo = $this->getRepository;

  my $obj;
  my $error;

  try {
    $obj = $repo->getObjectByPath('/This/Folder/Does/Not/Exist');
  } catch WebService::Cmis::ClientException with {
    $error = shift;
    ok(defined $error);
    like($error, '^404 Not Found');
  };

  ok(!defined $obj);
}

sub test_Repository_getObject : Test {
  my $this = shift;

  my $repo = $this->getRepository;
  my $root = $repo->getRootFolder;

  my $obj = $repo->getObject($root->getId);
  is($root->getId, $obj->getId);
}

sub test_Repository_getLink : Test(8) {
  my $this = shift;

  my $repo = $this->getRepository;
#  $repo->reload unless defined $repo->{xmlDoc};
#  my $linkNodes = $repo->{xmlDoc}->findnodes('//atom:link');
#  print STDERR "found ".$linkNodes->size." links\n";
#  print STDERR $_->toString."\n", foreach $linkNodes->get_nodelist;
#  print STDERR "\n";

  my $repoUrl = $this->{config}{url};
  $repoUrl =~ s/^(http:\/\/[^\/]+?):80\//$1\//g; # remove bogus :80 port

  my @rels = (FOLDER_TREE_REL, ROOT_DESCENDANTS_REL, TYPE_DESCENDANTS_REL);
  push @rels, CHANGE_LOG_REL if $repo->getCapabilities()->{'Changes'} && $repo->getCapabilities()->{'Changes'} ne 'none';

  foreach my $rel (@rels) {
    my $href = $repo->getLink($rel);

    ok(defined $href) or diag("link for $rel not found");
    next unless defined $href;

    $href =~ s/^(http:\/\/[^\/]+?):80\//$1\//g; # remove bogus :80 port
    like($href, qr/^$repoUrl/);
    note("found rel=$rel, href=$href");
  }
}

sub test_Repository_getLink_unknown : Test {
  my $this = shift;

  my $repo = $this->getRepository;
  my $href = $repo->getLink("foobar");
  ok(!defined $href);
}

sub test_Repository_getCheckedOutDocs : Tests {
  my $this = shift;

  my $repo = $this->getRepository;
  $this->deleteTestDocument;
  my $doc = $this->getTestDocument;
  note("before checkout id=".$doc->getId);
  $doc->checkOut;
  note("after checkout id=".$doc->getId);

  my $checkedOutDocs = $repo->getCheckedOutDocs;
  ok(defined $checkedOutDocs) or diag("can't get checked out docs");

  my $nrEntries = $checkedOutDocs->getSize;
  ok(defined $nrEntries) or diag("should have at least one document checked out");
  note("found $nrEntries checked out document(s)");

  while(my $doc = $checkedOutDocs->getNext) {
    my $id = $doc->getId;
    ok(defined $id);
    my $baseTypeId = $doc->getProperty("cmis:baseTypeId");
    ok(defined $baseTypeId);
    my $selfLink = $doc->getSelfLink;
    ok(defined $selfLink);
    note("id=$id, baseTypeId=$baseTypeId, url=$selfLink");
    isa_ok($doc, 'WebService::Cmis::Document');
  }

  note("before cancel checkout id=".$doc->getId);
  $doc->cancelCheckOut;
}

sub test_Repository_getTypeDefinitions : Tests {
  my $this = shift;

  my $repo = $this->getRepository;

  my $typeDefs = $repo->getTypeDefinitions;
  ok(defined $typeDefs) or diag("can't get type definitions");

  note("found ".$typeDefs->getSize." type definition(s)");

  while(my $objectType = $typeDefs->getNext) {
    isa_ok($objectType, 'WebService::Cmis::ObjectType');
    ok(defined $objectType->getId);
    ok(defined $objectType->getDisplayName);
    ok(defined $objectType->getQueryName);
    #print "id=".$objectType->getId.", displayName=".$objectType->getDisplayName.", description=".$objectType->getDescription.", link=".$objectType->getLink."\n";
    $objectType->reload;
    ok(defined $objectType->getId);
    ok(defined $objectType->getDisplayName);
    ok(defined $objectType->getQueryName);
  }
}

sub test_Repository_getTypeChildren : Tests {
  my $this = shift;
  my $repo = $this->getRepository;

  # get type defs
  foreach my $typeId (undef, 'cmis:document', 'cmis:folder') {
    my $set = $repo->getTypeChildren($typeId);
    ok(defined $set);
    ok($set->getSize > 0);

    note("found ".$set->getSize." objects(s)");
    while(my $objectType = $set->getNext) {
      isa_ok($objectType, 'WebService::Cmis::ObjectType');
      #print "id=".$objectType->getId.", displayName=".$objectType->getDisplayName.", description=".$objectType->getDescription.", link=".$objectType->getLink."\n";
    }
  }
}

sub test_Repository_getTypeDescendants : Tests {
  my $this = shift;
  my $repo = $this->getRepository;

  # get type defs
  foreach my $typeId (undef, 'cmis:document', 'cmis:folder') { 
    my $set = $repo->getTypeDescendants($typeId, depth=>1);
    ok(defined $set);
    note("found ".$set->getSize." objects(s) of type ".($typeId||'undef'));
    ok($set->getSize > 0);

    while(my $objectType = $set->getNext) {
      isa_ok($objectType, 'WebService::Cmis::ObjectType');
      #print "id=".$objectType->getId.", displayName=".$objectType->getDisplayName.", description=".$objectType->getDescription.", link=".$objectType->getLink."\n";
    }
  }
}

sub test_Repository_getQueryXmlDoc : Test {
  my $this = shift;
  my $repo = $this->getRepository;

  my $xmlDoc = $repo->_getQueryXmlDoc("select * from cmis:document", foo=>"bar");

  my $testString = <<'HERE';
<?xml version="1.0" encoding="UTF-8"?>
<query xmlns="http://docs.oasis-open.org/ns/cmis/core/200908/">
  <statement><![CDATA[select * from cmis:document]]></statement>
  <foo>bar</foo>
</query>
HERE

  note("xmlDoc=".$xmlDoc->toString(1));
  is($xmlDoc->toString(1), $testString) or $this->reportXmlDiff($xmlDoc->toString(1), $testString);
}

sub test_Repository_query : Test(14) {
  my $this = shift;

  my $repo = $this->getRepository;

  my $maxItems = 10;
  my $skipCount = 0;

  require WebService::Cmis::Property;

  foreach my $typeId ('cmis:folder', 'cmis:document') {
    my $feed = $repo->query("select * from $typeId", maxItems => $maxItems, skipCount => $skipCount);

    #note("feed=".$feed->{xmlDoc}->toString(1));

    my $dateTime = WebService::Cmis::Property::formatDateTime($feed->getUpdated);

    note("title=" . $feed->getTitle);
    note("generator=" . $feed->getGenerator);
    note("updated=" . $feed->getUpdated . " ($dateTime)");

    my $numItems = $feed->getSize;
    note("numItems=$numItems reported in feed while querying for $typeId");

    ok(defined $feed);
    ok(defined $feed->getTitle);
    ok(defined $feed->getGenerator);
    ok(defined $feed->getUpdated);
    like($feed->getUpdated, qr'^\d+(Z|[-+]\d\d(:\d\d)?)?$');
    like($feed->getSize, qr'^\d+$');

    # more checks
    my $countItems = 0;
    $countItems++ while my $obj = $feed->getNext;
    note("counted $countItems $typeId while crawling the feed");

    my $msg = $this->isBrokenFeature("numItems");
  SKIP: {
      skip $msg, 1 if $msg;

      is($countItems, $numItems) or diag("woops, wrong number of entries in feed");
    }
  }
}

sub test_Repository_query_jpg : Tests {

  my $this = shift;
  my $repo = $this->getRepository;
  $this->getTestDocument;

  my $feed = $repo->query("select * from cmis:document where cmis:name like '%jpg'");
  my $size = $feed->getSize();
  ok($size > 0) or diag("no jpegs found by query");

  while(my $obj = $feed->getNext) {
    my $title = $obj->getTitle;
    my $id = $obj->getId;
    ok(defined $title);
    ok(defined $id);

    my $props = $obj->getProperties;
    ok(defined $props);

    my @result = ();
    foreach my $key (keys %$props) {
      my $val = $props->{$key}->getValue;
      push @result, "$key=$val" if defined $val;
    }
    note(join("\n   ", @result));
  }

  note("size=$size");
}

sub test_Repository_createEntryXmlDoc_1 : Test {
  my $this = shift;
  my $repo = $this->getRepository;
  my $id = $repo->getRepositoryId;

  my $xmlDoc = $repo->createEntryXmlDoc(summary=>"hello world");
  note($xmlDoc->toString(1));

  my $xmlSource = <<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:app="http://www.w3.org/2007/app" xmlns:cmisra="http://docs.oasis-open.org/ns/cmis/restatom/200908/" xmlns:cmis="http://docs.oasis-open.org/ns/cmis/core/200908/">
  <summary>hello world</summary>
  <cmisra:object>
  </cmisra:object>
</entry>
HERE

  my $xmlDocString = $xmlDoc->toString(1);
  $xmlDocString =~ s/\n\s*?<cmis:repositoryId>.*?<\/cmis:repositoryId>\s*?\n/\n/;

  is($xmlDocString, $xmlSource) or $this->reportXmlDiff($xmlDocString, $xmlSource);
}

sub test_Repository_createEntryXmlDoc_2 : Test {
  my $this = shift;
  my $repo = $this->getRepository;
  my $id = $repo->getRepositoryId;

  require WebService::Cmis::Property;

  #print "nameProperty=".$nameProperty->toString."\n";

  my $xmlDoc = $repo->createEntryXmlDoc(
    properties => [
      WebService::Cmis::Property::newString(
        id => 'cmis:name',
        value => "hello world",
      ),
      WebService::Cmis::Property::newBoolean(
        id=>"cmis:isLatestMajorVersion",
        displayName=>"Is Latest Major Version",
        queryName=>"cmis:isLatestMajorVersion",
        value=>0,
      ),
      WebService::Cmis::Property::newDateTime(
        id=>"cmis:creationDate",
        displayName=>"Creation Date",
        queryName=>"cmis:creationDate",
        value=>WebService::Cmis::Property::parseDateTime("2011-01-25T13:22:28+01:00"),
      ),
      WebService::Cmis::Property::newString(
        id => 'cm:taggable',
        queryName => 'cm:taggable',
        displayName => 'Tags',
        value => ["foo", "bar", "baz"],
      ),
    ]
  );

  my $testString = <<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:app="http://www.w3.org/2007/app" xmlns:cmisra="http://docs.oasis-open.org/ns/cmis/restatom/200908/" xmlns:cmis="http://docs.oasis-open.org/ns/cmis/core/200908/">
  <cmisra:object>
    <cmis:properties>
      <cmis:propertyString propertyDefinitionId="cmis:name">
        <cmis:value>hello world</cmis:value>
      </cmis:propertyString>
      <cmis:propertyBoolean displayName="Is Latest Major Version" propertyDefinitionId="cmis:isLatestMajorVersion" queryName="cmis:isLatestMajorVersion">
        <cmis:value>false</cmis:value>
      </cmis:propertyBoolean>
      <cmis:propertyDateTime displayName="Creation Date" propertyDefinitionId="cmis:creationDate" queryName="cmis:creationDate">
        <cmis:value>2011-01-25T13:22:28+01:00</cmis:value>
      </cmis:propertyDateTime>
      <cmis:propertyString displayName="Tags" propertyDefinitionId="cm:taggable" queryName="cm:taggable">
        <cmis:value>foo</cmis:value>
        <cmis:value>bar</cmis:value>
        <cmis:value>baz</cmis:value>
      </cmis:propertyString>
    </cmis:properties>
  </cmisra:object>
  <title>hello world</title>
</entry>
HERE

  note($xmlDoc->toString(1));
  my $xmlDocString = $xmlDoc->toString(1);
  $xmlDocString =~ s/^\s//;
  $xmlDocString =~ s/\n\s*?<cmis:repositoryId>.*?<\/cmis:repositoryId>\s*?\n/\n/;

  is($xmlDocString, $testString) or $this->reportXmlDiff($xmlDocString, $testString);
}

sub test_Repository_createEntryXmlDoc_contentFile {
  my $this = shift;
  my $repo = $this->getRepository;

  my $testFile = $this->{testFile};
  ok(-e $testFile) or diag("testFile=$testFile not found");

  my $xmlDoc = $repo->createEntryXmlDoc(
    contentFile=>$testFile
  );

  note($xmlDoc->toString(1));
  #is($testString, $xmlDoc->toString(1));
}

sub test_Repository_createDocument_filed : Test {
  my $this = shift;
  my $repo = $this->getRepository;

  # set up test folder
  my $document = $this->getTestDocument;
 
  $document = $repo->getObjectByPath($this->getTestFolderPath."/free.jpg");
  ok(defined $document) or diag("can't find uploaded object ... should be available now");
}

sub test_Repository_createDocument_unfiled : Test(2) {
  my $this = shift;

  my $repo = $this->getRepository;
  my $canUnfiling = $repo->getCapabilities()->{'Unfiling'};
SKIP: {
    skip "repository not supporting unfiling", 2 unless $canUnfiling;

    my $testFile = $this->{testFile};
    ok(-e $testFile) or diag("testFile=$testFile not found");

    my $document = $repo->createDocument("free.jpg", contentFile => $testFile);

    ok(defined $document);
  }
}

sub test_Repository_getUnfiledDocs : Tests {
  my $this = shift;

  my $repo = $this->getRepository;
  my $canUnfiling = $repo->getCapabilities()->{'Unfiling'};

SKIP: {
    skip "repository not supporting unfiling", unless $canUnfiling;

    my $unfiledDocs = $repo->getUnfiledDocs;
    ok(defined $unfiledDocs) or diag("can't get unfiled docs");

    note("found " . $unfiledDocs->getSize . " unfiled document(s)");

    while (my $obj = $unfiledDocs->getNext) {
      note("name=" . $obj->getName . ", id=" . $obj->getId . ", url=" . $obj->getSelfLink);
      isa_ok($obj, 'WebService::Cmis::Document');
    }

  }

  # TODO create an unfiled document and test it
  #fail("WARNING: create an unfiled document and verify it is in the unfiled collection");
}

sub test_Repository_createFolder : Test {
  my $this = shift;
  my $repo = $this->getRepository;

  my $folder = $this->getTestFolder;

  $folder = $repo->getObjectByPath($this->getTestFolderPath);
  ok(defined $folder) or diag("folder should be available now");
}


1;

