package WebService::Cmis::Test;
use base qw(Test::Class);
use Test::More;

use constant TEST_FOLDER_PREFIX => "Test_";

use strict;
use warnings;

BEGIN {
  if (!eval { require "cmis.cfg"; 1 }) {
    plan skip_all => "WARNING: You need to create a cmis.cfg. See the example file in the inc/ directory.";
  } 
}

binmode(STDERR, ":utf8");
binmode(STDOUT, ":utf8");

use WebService::Cmis qw(:collections :utils :relations :namespaces :contenttypes);
use File::Temp ();
use Error qw(:try);
use Cache::FileCache ();
use XML::LibXML ();

my %brokenFeatures  = (
  "Alfresco" => {
    "numItems" => {
      version => [4.20],
      message => "counting results broken in Alfresco 4.2.0 (ALF-19186)", 
    },
    "paging" => {
      version => [4.20],
      message => "paging changes too buggy in Alfresco 4.2.0 (ALF-19173)", 
    },
    "updateSummary" => {
      message => "updating summary not available in OpenCMIS Connector", 
    }
  },
);

require "cmis.cfg";

sub new {
  my $class = shift;
  my $connection = shift || $ENV{CMIS_CONNECTION} || $WebService::Cmis{DefaultConnection};

  my $config = $WebService::Cmis{Connections}{$connection};
  die "ERROR: unknown connection $connection" unless defined $config;

  $config->{testRoot} ||= $WebService::Cmis{TestRoot};
  $config->{testFile} ||= $WebService::Cmis{TestFile};
  $config->{testXml} ||= $WebService::Cmis{TestXml};

  my $this = $class->SUPER::new(@_);
  $this->{config} = $config;

  note("connection=$connection");

  return $this;
}


sub DESTROY {
  my $this = shift;

  $this->reset;
  $this->{client}->logout if $this->{client};
  $this->{client} = undef;
}

sub reset {
  my $this = shift;

  foreach my $key (keys %{$this->{testFolders}}) {
    $this->deleteTestFolder($key);
  }

  $this->{testXmlDoc} = undef;
}

sub getClient {
  my $this = shift;

  unless (defined $this->{client}) {
    note("constructing a new client");
    my $cache;
    if ($this->{cacheEnabled}) {
      my $tempDir = File::Temp::tempdir(CLEANUP => 1);
      note("temporary cache in $tempDir");
      my $cache = Cache::FileCache->new({
        cache_root => $tempDir
        }
      );
    }

    $this->{testRoot} = delete $this->{config}{testRoot};
    $this->{testFile} = delete $this->{config}{testFile};

    $this->{client} = WebService::Cmis::getClient(
      %{$this->{config}},
      cache => $cache,
      @_
    );
    $this->{client}->login();
  }

  return $this->{client};
}

sub getRepository {
  return $_[0]->getClient->getRepository;
}

sub getTestFolderName {
  my $this = shift;
  my $key = shift;

  $key ||= 'default';
  $this->{testFolderNames} = {} unless defined $this->{testFolderNames};

  unless (defined $this->{testFolderNames}{$key}) {
    $this->{testFolderNames}{$key} = TEST_FOLDER_PREFIX.$key."_".time;
  }

  return $this->{testFolderNames}{$key};
}

sub getTestFolderPath {
  my $this = shift;
  my $key = shift;

  my $name = $this->getTestFolderName($key);
  return $this->{testRoot}."/".$name;
}

sub deleteTestFolder {
  my $this = shift;
  my $key = shift;

  $key ||= 'default';
  $this->{testFolders} = {} unless defined $this->{testFolders};

  note("called deleteTestFolder($key)");

  if (defined $this->{testFolders}{$key}) {
    $this->{testFolders}{$key}->deleteTree;
  }

  delete $this->{testFolders}{$key};
}

sub getTestFolder {
  my $this = shift;
  my $key = shift;

  $key ||= 'default';
  $this->{testFolders} = {} unless defined $this->{testFolders};

  note("called getTestFolder($key)");
  unless (defined $this->{testFolders}{$key}) {
    my $name = $this->getTestFolderName($key);
    die "testFolder does not start with '".TEST_FOLDER_PREFIX."'" unless $name =~ "^".TEST_FOLDER_PREFIX;

    my $repo = $this->getRepository;
    my $folder = $repo->getObjectByPath($this->{testRoot});
    die "no folder at $this->{testRoot}" unless defined $folder;
    note("testRoot=".$folder->getPath);

    note("creating sub-folder '$this->{testRoot}/$name'");
    $this->{testFolders}{$key} = $folder->createFolder($name, summary=>"this is a test folder used by WebService::Cmis' testsuite");

    my $id = $this->{testFolders}{$key}->getId;
    note("test folder id=$id");
    my $rootFolderId = $repo->getRepositoryInfo->{'rootFolderId'};
    if ($id eq $rootFolderId) {
      print STDERR "ERROR: don't use root as test folder\n\n";
      exit; #emergency
    }

    die "failed creating a test folder at $this->{testRoot}/$name" 
      unless defined $this->{testFolders}{$key};

    my $allowableActions = $folder->getAllowableActions;
    return unless $allowableActions->{canCreateDocument};
    return unless $allowableActions->{canCreateFolder};
  }

  return $this->{testFolders}{$key};
}

sub deleteTestDocument {
  my $this = shift;
  my $key = shift;

  $key ||= 'default';
  $this->{testDocuments} = {} unless defined $this->{testDocuments};

  note("called deleteTestDocument($key)");

  try {
    my $obj = $this->{testDocuments}{$key};
    if (defined $obj) {
      note("deleting test document id=".$obj->getId);
      $obj->delete;
      delete $this->{testDocuments}{$key};
    }
  } catch WebService::Cmis::ClientException with {
    my $error = shift;
    note("ERROR in deleteTestDocument: $error ... ignoring");
    # ignore
  };
}

sub getTestDocument {
  my $this = shift;
  my $key = shift;

  $key ||= 'default';

  note("called getTestDocument($key)");
  $this->{testDocuments} = {} unless defined $this->{testDocuments};

  unless (defined $this->{testDocuments}{$key}) {

    my $folder = $this->getTestFolder($key);
    die "can't get test folder" unless defined $folder;

    my $path = $folder->getPath();
    my $repo = $this->getRepository;

    my $testFile = $this->{testFile};
    die "got no {testFile}" unless -e $testFile;

    my $testFolderPath = $this->getTestFolderPath($key);
    die "can't get test folder path" unless defined $testFolderPath;

    die "woops repository created folder at path '$path' but we expected '$testFolderPath'" 
      unless $testFolderPath eq $path;

    die "invalid test folder '$testFolderPath'. please check the {testRoot} setting"
      unless $repo->getObjectByPath($testFolderPath);

    # first delete it if it exists
    $path = "$testFolderPath/free.jpg";
    note("path=$path");

    note("uploading $testFile to $path");
    my $document = $folder->createDocument(
      "free.jpg",
      summary => "this is a file folder used by WebService::Cmis' testsuite",
      contentFile => $testFile
    );
    die "unable to create test document at $path" unless defined $document;
    note("new document=".$document->toString);

    $this->{testDocuments}{$key} = $document;
  }

  return $this->{testDocuments}{$key};
}

sub getTestXml {
  my $this = shift;
  my $key = shift;

  unless (defined $this->{testXmlDoc}{$key}) {
    my $fileName = $this->{config}{testXml}{$key};
    die "no testXml for '$key'" unless defined $fileName;

    die "file not found '$fileName'" unless -e $fileName;
    my $doc = XML::LibXML->load_xml(location=>$fileName);
    $this->{testXmlDoc}{$key} = $doc->documentElement;
  }

  return $this->{testXmlDoc}{$key};
}

sub diffXml {
  my ($this, $xml1, $xml2) = @_;

  unless (defined $this->{differ}) {
    require XML::SemanticDiff;
    $this->{differ} = XML::SemanticDiff->new(keeplinenums => 1);
  }

  return $this->{differ}->compare($xml1, $xml2);
}

sub reportXmlDiff {
  my ($this, $xml1, $xml2, $changes) = @_;

  $changes = [$this->diffXml($xml1, $xml2)] unless defined $changes;

  foreach my $change (@$changes) {
    diag("  $change->{message} (between lines $change->{startline} and $change->{endline})");
  }
}

sub testXml {
  my ($this, $xml1, $xml2, $testName) = @_;

  my @changes = $this->diffXml($xml1, $xml2);
  if (@changes) {
    fail($testName);
    $this->reportXmlDiff($xml1, $xml2, \@changes);
  }
}

sub isBrokenFeature {
  my ($this, $feature) = @_;

  #print STDERR "called isBrokenFeature($feature)\n";

  my $repo = $this->getRepository();
  my $vendorName = $repo->getRepositoryInfo->{vendorName};

  my $record = $brokenFeatures{$vendorName}{$feature};
  unless (defined $record) {
    note("no feature record found for $vendorName");
    return;
  }

  # test feature
  return $record->{message} unless defined $record->{version};

  # test version
  my $productVersion = $repo->getRepositoryInfo->{productVersion};
  my $major = 0;
  my $minor = 0;
  my $patch = 0;
  ($major, $minor, $patch) = $productVersion =~ /(\d+)\.(\d+)\.(\d+)/;
  $productVersion = $major + $minor / 10 + $patch / 100;

  if (ref($record->{version})) {
    foreach my $v (@{$record->{version}}) {
      return $productVersion == $v?$record->{message}:"";
    }
  } else {
    return $record->{message} if $productVersion <= $record->{version};
  }
}

1;
