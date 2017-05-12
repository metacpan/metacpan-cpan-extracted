package WebService::Cmis::Test::Document;
use base qw(WebService::Cmis::Test);

use strict;
use warnings;

use Error qw(:try);
use Test::More;
use WebService::Cmis qw(:collections :utils :relations :namespaces :contenttypes);

sub _getParents {
  my $obj = shift;

  note("called _getParents for obj=".$obj->getName.", id=".$obj->getId.", path=".($obj->getPath||''));

  my $parents = $obj->getObjectParents;

  my @parents = ();
  if ($parents->isa("WebService::Cmis::AtomFeed")) {
    note("nr parents: ".$parents->getSize);
    push @parents, $_ while $_ = $parents->getNext;
  } else {
    push @parents, $parents;
  }

  return @parents;
}

sub _saveFile {
  my ($name, $text) = @_;
  my $FILE;
  unless (open($FILE, '>', $name)) {
    die "Can't create file $name - $!\n";
  }
  print $FILE $text;
  close($FILE);
}

sub test_Document_getAllVersions : Tests {
  my $this = shift;
  my $repo = $this->getRepository;
  my $root = $repo->getRootFolder;
  my $resultSet = $root->getDescendants(depth=>2);

  ok(defined $resultSet) or diag("can't fetch results");

  note("found ".$resultSet->getSize." documents in root collection");

  while(my $obj = $resultSet->getNext) {
    next unless $obj->isa("WebService::Cmis::Document");

    note("versions in ".$obj->getId.", url=".$obj->getSelfLink);
    my $allVersions = $obj->getAllVersions;
    ok(defined $allVersions);
    ok($allVersions->getSize > 0) or diag("no versions for ".$obj->toString);

    while(my $version = $allVersions->getNext) {
      note("version=".$version->toString);
      my $props = $version->getProperties;

      # SMELL: which of these are standard, which are nice-to-haves by alfresco?
      foreach my $propId (qw(cmis:contentStreamFileName cmis:name
        cmis:baseTypeId cmis:isImmutable cmis:isLatestMajorVersion cmis:changeToken
        cmis:isVersionSeriesCheckedOut cmis:objectTypeId cmis:createdBy
        cmis:versionSeriesId cmis:versionSeriesCheckedOutBy cmis:lastModificationDate
        cmis:versionSeriesCheckedOutId cmis:isLatestVersion cmis:objectId
        cmis:checkinComment cmis:versionLabel cmis:creationDate cmis:contentStreamId
        cmis:contentStreamLength cmis:contentStreamMimeType cmis:lastModifiedBy
        cmis:isMajorVersion)) {
        note("   $propId=".($props->{$propId}->getValue||''));
        ok(defined $props->{$propId}) or diag("property $propId not defined");
      }
    }
  }
}

sub test_Document_checkOut_checkIn : Tests {
  my $this = shift;

  my $repo = $this->getRepository;
  my $obj = $this->getTestDocument;

  my $isCheckedOut = $obj->isCheckedOut;
  note("isCheckedout=$isCheckedOut");
  is($isCheckedOut, 0) or diag("test document is checked out");

  note("before checking out, id=".$obj->getId." version=".($obj->getProperty("cmis:versionLabel")||''));

  $obj->checkOut;
  $isCheckedOut = $obj->isCheckedOut;
  note("isCheckedout=$isCheckedOut");
  is($isCheckedOut, 1) or diag("test document is NOT checked out");

  note("after checking out, id=".$obj->getId." version=".($obj->getProperty("cmis:versionLabel")||''));

  my $checkedOutBy = $obj->getCheckedOutBy;
  note("checkedOutBy=$checkedOutBy");
  ok(defined $checkedOutBy) or diag("no information checked out by");
 
  note("checking in");
  $obj->checkIn("this is a test checkin time=".time, major=>'true');

  $obj->getLatestVersion;
  note("finally id=".$obj->getId." version=".($obj->getProperty("cmis:versionLabel")||''));
 
  $this->deleteTestDocument;
}

sub test_Document_getContentStream : Test(2) {
  my $this = shift;

  my $obj = $this->getTestDocument;

  my $content = $obj->getContentStream;
  ok(defined $content);

  my $name = $obj->getName;
  ok(defined $name);
  note("name=$name");
  _saveFile("/tmp/downloaded_$name", $content);

}

sub test_Document_setContentStream : Test(6) {
  my $this = shift;

  my $repo = $this->getRepository;
  my $contentStreamUpdatability = $repo->getCapabilities->{'ContentStreamUpdatability'};

  note("contentStreamUpdatability=$contentStreamUpdatability");

SKIP: {
    skip "setContentStream not supported", 6, if $contentStreamUpdatability eq 'none';

    my $obj = $this->getTestDocument;
    my $id = $obj->getId;

    note("before id=$id");

    my $versionLabel = $obj->getProperty("cmis:versionLabel");
    ok(defined $versionLabel);
    note("versionLabel=$versionLabel");

    $obj->setContentStream(contentFile => $this->{testFile});

    $id = $obj->getId;
    note("after id=$id");

    ok(defined $obj->{xmlDoc});

    #print STDERR "xmlDoc=".$obj->{xmlDoc}->toString(1)."\n";

    my $updatedVersionLabel = $obj->getProperty("cmis:versionLabel");
    ok(defined $updatedVersionLabel);
    note("versionLabel=$versionLabel, updatedVersionLabel=" . ($updatedVersionLabel || 'undef'));
    ok($contentStreamUpdatability ne 'pwconly' || $versionLabel ne $updatedVersionLabel) or 
      diag("should have created a new version when updating the content stream");

    my $contentStreamMimeType = $obj->getProperty("cmis:contentStreamMimeType");

    #print STDERR "contentStreamMimeType=$contentStreamMimeType\n";
    is($contentStreamMimeType, "image/jpeg");

    $obj->getLatestVersion;
    my $latestVersionLabel = $obj->getProperty("cmis:versionLabel");

    #print STDERR "xmlDoc=".$obj->{xmlDoc}->toString(1)."\n";
    note("latestVersionLabel=$latestVersionLabel");
    is($updatedVersionLabel, $latestVersionLabel);

    $this->deleteTestDocument;
  }
}

sub test_Document_getContentLink : Test {
  my $this = shift;

  my $obj = $this->getTestDocument;
  my $contentLink = $obj->getContentLink;
  note("content-link=$contentLink");
  ok(defined $contentLink) or diag("can't get content link for test file");

}

sub test_Document_moveTo : Test(5) {
  my $this = shift;

  my $repo = $this->getRepository;
  my $obj = $this->getTestDocument("source");

  my ($parent1) = _getParents($obj);
  my $sourcePath = $parent1->getPath."/".$obj->getName;
  note("sourcePath=".$sourcePath);
  note("parents: ".join(", ", map($_->getName, _getParents($obj))));

  my $targetFolder = $this->getTestFolder("target");
  my $targetPath = $targetFolder->getPath."/".$obj->getName;
  note("targetPath=$targetPath");
  isnt($targetPath, $sourcePath);

  $obj->moveTo($targetFolder);

  my ($parent2) = _getParents($obj);
  note("parents: ".join(", ", map($_->getName, _getParents($obj))));

  is(1, scalar(_getParents($obj))) or diag("not the same number of parents");
  isnt($parent1->getId, $parent2->getId) or diag("should have changed folder");

  my $result = $repo->getObjectByPath($sourcePath);
  ok(!defined $result) or diag("document should NOT be located in source folder anymore");

  $result = $repo->getObjectByPath($targetPath);
  ok(defined $result) or diag("document should be located in target folder");
}

sub test_Document_move : Test(4) {
  my $this = shift;
  my $repo = $this->getRepository;

  my $obj = $this->getTestDocument("source");
  my $name = $obj->getName;
  note("name=$name");

  my $targetFolder = $this->getTestFolder("target");
  my $targetPath = $targetFolder->getPath."/".$name;
  
  my ($sourceFolder) = _getParents($obj);
  ok(defined $sourceFolder);

  my $sourcePath = $sourceFolder->getPath."/".$name;

  note("targetPath=$targetPath, sourcePath=$sourcePath");
  isnt($targetPath, $sourcePath);
  $obj->moveTo($targetFolder);

  #find the document at two paths now
  my $test = $repo->getObjectByPath($targetPath);
  ok(defined $test) or diag("document not found at target location");

  $test = $repo->getObjectByPath($sourcePath);
  ok(!defined $test) or diag("document still found at source location");

  $this->deleteTestDocument("source");
}

sub test_Document_unfile : Tests {
  my $this = shift;
  my $repo = $this->getRepository;

  my $exceptionOk = 0;
  my $obj = $this->getTestDocument;
  my $error;

  try {
    $obj->unfile;
  } catch WebService::Cmis::NotSupportedException with {
    $error = shift;
    is($error, "This repository does not support unfiling");
    $exceptionOk = 1;
  };
  return $error if $exceptionOk;

  my $unfiledDocs = $repo->getUnfiledDocs;
  ok(defined $unfiledDocs) or diag("can't get unfiled docs");

  note("found ".$unfiledDocs->getSize." unfiled document(s)");

  while(my $obj = $unfiledDocs->getNext) {
    note("name=".$obj->getName.", id=".$obj->getId.", url=".$obj->getSelfLink);
    isa_ok($obj, 'WebService::Cmis::Document');
  }

}

sub test_Document_getRenditions : Tests {
  my $this = shift;

  my $repo = $this->getRepository;
  my $vendorName = $repo->getRepositoryInfo->{vendorName};
  my $productVersion = $repo->getRepositoryInfo->{productVersion};

SKIP: {
    skip "renditions strange in Alfresco 4.2.0", 1, if $vendorName eq 'Alfresco' && $productVersion =~ /^4\.2\.0/;

    my $obj = $this->getTestDocument;

    #print STDERR "xmlDoc=".$obj->{xmlDoc}->toString(1)."\n";

    my $renditions = $obj->getRenditions;
    ok(defined $renditions);
    note("renditions:");
    foreach my $rendition (values %$renditions) {
      ok(defined $rendition);
      note("rendition properties:" . join(", ", sort keys %$rendition));
      ok(defined $rendition->{streamId});
      ok(defined $rendition->{mimetype});
      ok(defined $rendition->{kind});
      my @info = ();
      foreach my $key (keys %$rendition) {
        push @info, "   $key=$rendition->{$key}";
      }
      note(join("\n", @info));
    }
  }
}

sub test_Document_getRenditionLink : Tests {
  my $this = shift;

  SKIP: {
    skip "unclear when this is implemented by repos";

    my $obj = $this->getTestDocument;
    my $link = $obj->getRenditionLink(kind=>"thumbnail");
    #the server might delay thumbnail creation beyond this test
    #ok(defined $link);
    #note("thumbnail=$link");

    $link = $obj->getRenditionLink(mimetype=>"Image");
    ok(defined $link);
    note("image=$link");

    $link = $obj->getRenditionLink(mimetype=>"Image", width=>16);
    ok(defined $link) || diag("no image/16 rendition");
    note("image,16=$link");

    # not implemetned by some repos
    #
    # $link = $obj->getRenditionLink(mimetype=>"Image", width=>32);
    # ok(defined $link) || diag("no image/32 rendition");
    # note("image,32=".($link||'undef'));

    # $link = $obj->getRenditionLink(kind=>"icon", height=>16);
    # ok(defined $link) || diag("no icon/16 rendition");
    # note("icon=".($link||'undef'));

    $link = $obj->getRenditionLink(kind=>"icon", height=>11234020);
    ok(!defined $link);
  }
}

sub test_Document_getLatestVersion : Test(9) {
  my $this = shift;

  my $repo = $this->getRepository;

  $this->deleteTestDocument;
  my $doc = $this->getTestDocument;

  my $versionLabel = $doc->getProperty("cmis:versionLabel");
  note("versionLabel=$versionLabel");
  is($versionLabel, "1.0");

  note("before checkout id=".$doc->getId);

  my $beforeCheckedOutDocs = $repo->getCheckedOutDocs;
  note("before checkout size=".$beforeCheckedOutDocs->getSize);

  my $checkedOutDocs = $repo->getCheckedOutDocs;
  while (my $entry = $checkedOutDocs->getNext) {
    note("checked doc id=".$entry->getId);
  }

  $doc->checkOut;

  $checkedOutDocs = $repo->getCheckedOutDocs;
  note("after checkout id=".$doc->getId);
  note("after checkout size=".$checkedOutDocs->getSize);
  while (my $entry = $checkedOutDocs->getNext) {
    note("checked doc id=".$entry->getId." version=".($entry->getProperty("cmis:versionLabel")||''));
  }

  is($checkedOutDocs->getSize, $beforeCheckedOutDocs->getSize+1) or diag("checked out queue should be increasing");

  $doc->checkIn("this is a major checkin time=".time);

  note("after checkin id=".$doc->getId);

  $checkedOutDocs = $repo->getCheckedOutDocs;
  while (my $entry = $checkedOutDocs->getNext) {
    note("checked doc id=".$entry->getId);
  }

  is($checkedOutDocs->getSize, $beforeCheckedOutDocs->getSize) or diag("expected the checkedout queue to be the same as before");

  $doc->getLatestVersion();

  my $latestVersionDocId = $doc->getId;
  note("latestVersionDocId=$latestVersionDocId");

  my $isLatestMajorVersion = $doc->getProperty("cmis:isLatestMajorVersion");
  note("isLatestMajorVersion=$isLatestMajorVersion");
  ok($isLatestMajorVersion);
 
  my $isLatestVersion = $doc->getProperty("cmis:isLatestVersion");
  note("isLatestVersion=$isLatestVersion");
  ok($isLatestVersion);
 
  $versionLabel = $doc->getProperty("cmis:versionLabel");
  note("latest versionLabel=$versionLabel");
  is("2.0", $versionLabel);
 
  $doc->checkOut;
  $doc->checkIn("this is a minor test checkin time=".time, major=>0);
 
  $doc->getLatestVersion;
  $versionLabel = $doc->getProperty("cmis:versionLabel");
  note("latest versionLabel=$versionLabel");
  is("2.1", $versionLabel);

  $doc->getLatestVersion(major=>1);
  $versionLabel = $doc->getProperty("cmis:versionLabel");
  note("latest major versionLabel=$versionLabel");
  is($versionLabel, "2.0");

  is($repo->getCheckedOutDocs->getSize, $beforeCheckedOutDocs->getSize) or diag("checked out queue the same as before");

  $this->deleteTestDocument;
}

sub test_Document_checkOut_cancelCheckOut : Test(6) {
  # SMELL: skip some when there is no support for pwc

  my $this = shift;

  my $repo = $this->getRepository;
  my $obj = $this->getTestDocument;

  my $id = $obj->getId;
  note("id=$id");
 
  my $pwc = $obj->checkOut;
  my $pwcId = $pwc->getId;
  note("pwcId=$pwcId");
  ok($repo->getObject($pwcId));

  my $pwc2 = $obj->getPrivateWorkingCopy;
  ok(defined $pwc2);
  my $pwcId2 = $pwc2->getId;
  note("pwcId2=$pwcId2");
  ok($repo->getObject($pwcId2));
  is($pwcId2, $pwcId);
 
  $obj->cancelCheckOut;
 
  $id = $obj->getId;
  note("id=".$id);
  ok($repo->getObject($id));

  $pwc = $obj->getPrivateWorkingCopy;
  ok(!defined $pwc);
}

1;
