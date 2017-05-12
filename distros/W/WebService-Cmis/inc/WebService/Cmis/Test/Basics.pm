package WebService::Cmis::Test::Basics;
use base qw(WebService::Cmis::Test);

use strict;
use warnings;

use Test::More;
use Error qw(:try);
use WebService::Cmis qw(:collections :utils :relations :namespaces :contenttypes);

sub test_getClient : Test(1) {
  my $this = shift;

  my $client = WebService::Cmis::getClient;
  is($client->toString, "CMIS client connection to ");
}

sub test_getClient_2 : Test(1) {
  my $this = shift;

  my $client = $this->getClient;
  my $url = $this->{config}{url};

  is($client->toString, "CMIS client connection to $url");
}

sub test_repository_ClientException_40x : Test(4) {
  my $this = shift;

  my $client = $this->getClient;

  my $doc;
  try {
    #$doc = $client->get("does_not_exist"); ... well this one should fail with a 404 as well but it doesnt on alfresco 4
    $doc = $client->get("does/not/exist"); # anyway, this one fails with a 405 method not allowed on alfresco 
    print STDERR "doc=".$doc->toString(1)."\n"; # never reach
  } catch WebService::Cmis::ClientException with {
    my $error = shift;
    ok(ref($error));
    note("error=$error");
    isa_ok($error, "WebService::Cmis::ClientException");
    like($error, qr/^40\d/);
  };

  ok(!defined $doc);
}

sub test_repository_ClientExcepion_No_Access : Test(4) {
  my $this = shift;

  my $result;
  my $error;

  try {

    my $badClient = WebService::Cmis::getClient(
      %{$this->{config}},
    );

    my $ticket = $badClient->login(
      user=>"foo", 
      password=>"bar"
    );

    $result = $badClient->get;
  } catch WebService::Cmis::ClientException with {
    $error = shift;
  };

  ok(ref($error)) || diag("there should be an error by now");

  note("error=$error");

  isa_ok($error, "WebService::Cmis::ClientException");
  like($error, qr/^(401 Unauthorized)|(403 Forbidden|400)/);

  ok(!defined $result);
}

sub test_repository_ServerExceptio_500 : Test(4) {
  my $this = shift;

  my $badClient = WebService::Cmis::getClient(
    url => "http://doesnotexist.local.foobar:8080/alfresco/service/cmis",
    user => "foo",
    password => "bar",
  );

  my $result;
  try {
    $result = $badClient->get;
  } catch WebService::Cmis::ServerException with {
    my $error = shift;
    ok(ref($error));
    isa_ok($error, "WebService::Cmis::ServerException");
    #note("error=$error");
    like($error, qr/^500 Can't connect/);
  };

  ok(!defined $result);
}

sub test_repository_raw : Test(1) {
  my $this = shift;

  my $client = $this->getClient;
  my $doc = $client->get;
  like($doc->toString, qr/^<\?xml version="1.0"( encoding="(utf|UTF)-8")?\?>.*/);
}

sub test_Cmis_collectionTypes : Test(5) {
  my $this = shift;

  is("query", QUERY_COLL);
  is("types",TYPES_COLL);
  is("checkedout",CHECKED_OUT_COLL);
  is("unfiled",UNFILED_COLL);
  is("root",ROOT_COLL,);
}

sub test_getTestDocument : Test(1) {
  my $this = shift;

  my $doc = $this->getTestDocument;
  ok(defined $doc);
}

sub test_getTestFolder : Test(4) {
  my $this = shift;

  my $folderName = $this->getTestFolderName;
  note("test folder at $folderName");

  my $folder = $this->getTestFolder;
  ok(defined $folder);

  my $id = $folder->getId;
  note("folder id=$id");
  ok(defined $id);

  my $repo = $this->getRepository;
  my $folder1 = $repo->getObject($id);
  ok(defined $folder1);

  my $id1 = $folder->getId;
  is($id, $id1);
}

1;
