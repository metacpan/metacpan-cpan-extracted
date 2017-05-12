package WebService::Cmis::Test::AtomFeed;
use base qw(WebService::Cmis::Test);

use strict;
use warnings;

use Test::More;
use Error qw(:try);
use WebService::Cmis qw(:collections :utils :relations :namespaces :contenttypes);

sub test_AtomFeed : Tests {
  my $this = shift;

  my $repo = $this->getRepository;
  my $productName = $repo->getRepositoryInfo->{productName};

  my $resultSet = $repo->getCollection(ROOT_COLL);
  my $nrResults = $resultSet->getSize;
  ok($nrResults > 0) or diag("no objects in root collection");

  #print STDERR "found $nrResults results\n";

  while (my $obj = $resultSet->getNext) {
    isa_ok($obj, "WebService::Cmis::Object");

    #print STDERR "name=".$obj->getName." type=".$obj->getTypeId." path=".($obj->getPath||'')."\n";
    #print STDERR "toString=".$obj->toString."\n";
    #print STDERR "xmlDoc=".$obj->{xmlDoc}->toString(1)."\n";
    ok(defined $obj->getName);
    ok(defined $obj->getTypeId);
    ok(defined $obj->toString);
    if ($obj->isa("WebService::Cmis::Folder")) {
      ok(defined $obj->getPath);
      like($obj->getPath, qr"^/");

    SKIP: {
        skip "$productName does not maintain the object name as used in its path", 1
          if $productName =~ /nuxeo/i;    # SMELL: make it configurable

        my $regex = $obj->getName . '$';
        note("path=" . $obj->getPath . ", regex=$regex");
        like($obj->getPath, qr/$regex/);
      }

    }
    ok(!ref($obj->toString)) or diag("illegal objectId");
  }
}

sub test_AtomFeed_rewind : Test {
  my $this = shift;

  my $repo = $this->getRepository;

  my $resultSet = $repo->getCollection(ROOT_COLL);
  my $size1 = $resultSet->getSize;
  #print STDERR "resultSet1=".$resultSet->{xmlDoc}->toString(1)."\n";

  $resultSet->rewind;
  #print STDERR "resultSet2=".$resultSet->{xmlDoc}->toString(1)."\n";

  my $size2 = $resultSet->getSize;

  #print STDERR "size1=$size1, size2=$size2\n";

  is($size1, $size2);
}

sub test_AtomFeed_getSelfLinks_RootCollection : Tests {
  my $this = shift;

  my $repo = $this->getRepository;
  my $collection = $repo->getCollection(ROOT_COLL);
  my $nrEntries = $collection->getSize;
  note("found $nrEntries objects in root collection");
  ok($nrEntries);

  my $selfUrl = $collection->getLink(SELF_REL);
  note("self url of collection=$selfUrl");
  ok($selfUrl);

  my $index = 0;
  if ($collection->getSize > 0) {
    my $obj = $collection->getNext;
    ok(defined $obj) or diag("no object found in non-zero feed");
    do {
      isa_ok($obj, "WebService::Cmis::Object");
      my $id = $obj->getId;
      my $url = $obj->getSelfLink;
      my $title = $obj->getTitle;
      my $summary = $obj->getSummary;
      ok(defined $id);
      ok(defined $url);
      ok(defined $title);
      ok(defined $summary);
      note("title=$title, summary=$summary, url=$url");
      $index++;
    } while ($obj = $collection->getNext);
  }

  is($index, $nrEntries);
}

sub test_AtomFeed_getSelfLinks_getDescendants : Tests {
  my $this = shift;

  my $repo = $this->getRepository;
  my $root = $repo->getRootFolder;

  my $resultSet = $root->getDescendants(depth=>2);
  my $nrEntries = $resultSet->getSize;
  note("found $nrEntries objects in result set");
  #print STDERR "self url of result set=".$resultSet->getLink(SELF_REL)."\n";

  my $index = 0;
  while(my $obj = $resultSet->getNext) {
    isa_ok($obj, "WebService::Cmis::Object");
    my $id = $obj->getId;
    my $url = $obj->getSelfLink;
    my $title = $obj->getTitle;
    note("title=$title, id=$id, url=$url");
    $index++;
  }

  is($index, $nrEntries);
}

sub test_AtomFeed_reverse : Tests {
  my $this = shift;

  my $repo = $this->getRepository;
  my $collection = $repo->getCollection(ROOT_COLL);

  my $nrEntries = $collection->getSize;
  #print STDERR "found $nrEntries objects in root collection\n";

  my $index = 1;
  if ($nrEntries > 0) {

    my $lastObj = $collection->getLast;
    my $lastObjId = $lastObj->getId;
    ok(defined $lastObj) or diag("no object found in non-zero feed");

    #print STDERR  "1 - index=$collection->{index} - lastObj=".$lastObjId.", ".$lastObj->getTitle."\n";
    
    while (my $obj = $collection->getPrev) {
      isa_ok($obj, "WebService::Cmis::Object");
      $index++;

      ok($collection->{index} >= 0) or diag("illegal index in AtomFeed");

      isnt($obj->getId, $lastObjId) or diag("can't travel backwards in atom feed");

      #print STDERR  "2 - index=$collection->{index} -     obj=".$obj->getId.", ".$obj->getTitle."\n";
    };
  }

  is($index, $nrEntries);
}

sub test_AtomFeed_getAllowableActions : Tests {
  my $this = shift;

  my $repo = $this->getRepository();
  my $feed = $repo->query("select * from cmis:document", maxItems => 1);
  ok(defined $feed);

  while (my $obj = $feed->getNext) {
    my $allowableActions = $obj->getAllowableActions;
    ok(defined $allowableActions) or diag("can't get allowable actions");

    foreach my $action (sort keys %$allowableActions) {
      note("$action=$allowableActions->{$action}");
      like($action, qr'^can');
      like($allowableActions->{$action}, qr'^(0|1)$');
    }
    last;    # only check the first one
  }

}

sub test_AtomFeed_getACL : Test(2) {
  my $this = shift;

  my $repo = $this->getRepository();
  my $obj = $this->getTestDocument;
  my $feed = $repo->query("select * from cmis:document", maxItems => 1);
  ok(defined $feed);

  #print STDERR "feed=".$feed->{xmlDoc}->toString(1)."\n";

  my $canACL = $repo->getCapabilities()->{'ACL'};

SKIP: {
    skip "not able to manage ACLs", 1 unless $canACL eq 'manage';

    while (my $obj = $feed->getNext) {
      my $acl = $obj->getACL;
      ok(defined $acl) or diag("can't get ACLs");
      note($acl->toString);

      last;    # only check the first one
    }
  }
}

sub test_AtomFeed_getSelfLink : Tests {
  my $this = shift;

  my $repo = $this->getRepository();
  my $imageQuery;
  my $vendorName = $repo->getRepositoryInfo->{vendorName};

  # SMELL: argh ... more vendor differences to deal with
  $imageQuery = "select * from cmis:document where cmis:objectTypeId='Picture'" if $vendorName =~ /nuxeo/i;
  $imageQuery = "select * from cmis:document where cmis:contentStreamMimeType='image/jpeg'" unless defined $imageQuery;

  my $feed = $repo->query($imageQuery, maxItems => 1);
  ok(defined $feed);

  #print STDERR "feed=".$feed->{xmlDoc}->toString(1)."\n";

  while (my $obj = $feed->getNext) {
    my $link = $obj->getSelfLink;
    ok(defined $link) or diag("can't get self link");
    note("self link=$link");

    last;    # only check the first one
  }
}

sub test_AtomFeed_getEditLink : Tests {
  my $this = shift;

  my $repo = $this->getRepository();
  my $obj = $this->getTestDocument;

  my $imageQuery;
  my $vendorName = $repo->getRepositoryInfo->{vendorName};

  # SMELL: argh ... more vendor differences to deal with
  $imageQuery = "select * from cmis:document where cmis:objectTypeId='Picture'" if $vendorName =~ /nuxeo/i;
  $imageQuery = "select * from cmis:document where cmis:contentStreamMimeType='image/jpeg'" unless defined $imageQuery;

  my $feed = $repo->query($imageQuery, maxItems => 1);
  ok(defined $feed);

  #print STDERR "feed=".$feed->{xmlDoc}->toString(1)."\n";
  my $size = $feed->getSize;
  note("found $size item(s)");
  ok($size > 0) or diag("can't find image document anymore");

  while (my $obj = $feed->getNext) {
    my $link = $obj->getEditLink;
    ok(defined $link) or diag("can't get edit link");
    note("link=$link");

    last;    # only check the first one
  }
}

1;
