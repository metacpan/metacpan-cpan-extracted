package WebService::Cmis::Test::Folder;
use base qw(WebService::Cmis::Test);

use strict;
use warnings;

use Test::More;
use Error qw(:try);
use WebService::Cmis qw(:collections :utils :relations :namespaces :contenttypes);

sub test_Folder_getChildrenLink : Test {
  my $this = shift;
  my $repo = $this->getRepository;
  my $root = $repo->getRootFolder();
  my $childrenLink = $root->getChildrenLink();
  note("childrenLink=$childrenLink");

  my $href = $this->{config}{url};
  $href =~ s/^(http:\/\/[^\/]+?):80\//$1\//g; # remove bogus :80 port
  $childrenLink =~ s/^(http:\/\/[^\/]+?):80\//$1\//g; # remove bogus :80 port

  like($childrenLink, qr"^$href");
}

sub test_Folder_getChildren : Tests {
  my $this = shift;

  my $repo = $this->getRepository;
  my $root = $repo->getRootFolder();
  my $children = $root->getChildren();
  note("children=$children");
  while(my $obj = $children->getNext) {
    note($obj->getPath ."(".$obj->getTypeId.")");
    isa_ok($obj, 'WebService::Cmis::Object');
  }
}

sub test_Folder_getDescendantsLink : Test {
  my $this = shift;

  my $repo = $this->getRepository;
  my $root = $repo->getRootFolder();
  my $descendantsLink = $root->getDescendantsLink();
  note("descendantsLink=$descendantsLink");

  my $href = $this->{config}{url};
  $href =~ s/^(http:\/\/[^\/]+?):80\//$1\//g; # remove bogus :80 port
  $descendantsLink =~ s/^(http:\/\/[^\/]+?):80\//$1\//g; # remove bogus :80 port

  like($descendantsLink, qr"^$href");
}

sub test_Folder_getDescendants : Tests {
  my $this = shift;

  my $repo = $this->getRepository;
  my $root = $repo->getRootFolder();
  my $descendants;
  my $exceptionOk = 0;
  my $error;

  try {
    $descendants = $root->getDescendants(depth=>2); 
  } catch WebService::Cmis::NotSupportedException with {
    $error = shift;
    like($error, "This repository does not support getDescendants");
    $exceptionOk = 1;
  };
  return $error if $exceptionOk;

  note("found ".$descendants->getSize." descdendants at ".$root->getName);
  while(my $obj = $descendants->getNext) {
    note("path=".($obj->getPath||'').", title=".$obj->getTitle.", summary=".$obj->getSummary.", url=".$obj->getSelfLink);
    ok(defined $obj);
    isa_ok($obj, "WebService::Cmis::Object");
  }
}

sub test_Folder_getFolderTree : Tests {
  my $this = shift;
  my $repo = $this->getRepository;
  my $root = $repo->getRootFolder;

  my $tree = $root->getFolderTree(depth=>2);
  note("found ".$tree->getSize." objects");
  while(my $obj = $tree->getNext) {
    note("obj=$obj, name=".$obj->getName.", id=".$obj->getId.", url=".$obj->getSelfLink);
    isa_ok($obj, 'WebService::Cmis::Folder');
  }
}

1;
