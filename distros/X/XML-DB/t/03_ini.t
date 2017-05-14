# t/03_ini.t; 
use Test::More tests => 11;

# create test collection first (why is there no way to create the
# initial collection in the API?)
use XML::DB::Database;
my $driver = new XML::DB::Database($ENV{'DRIVER'});
$driver->setURI($ENV{'URL'});
eval { # try
	$driver->createCollection('/db', 'test');
	};
if ($@){ # catch
	unless ($@ =~ /Duplicate Collection/){
		die $@; # no point in going on...
	}
}
use XML::DB::Database;
my $db = new XML::DB::Database($ENV{'DRIVER'});
$db->setURI($ENV{'URL'});


# 1 load
use XML::DB::DatabaseManager;
my($loaded) = 1;
ok($loaded, "Checking DatabaseManager.pm exists");

#2 Create the DatabaseManager
my $dbm = new XML::DB::DatabaseManager();
ok(ref($dbm), 'created DB manager');

# 3 register driver
$dbm->registerDatabase($ENV{'DRIVER'});
my $dbs = $dbm->getDatabases();
ok(defined $dbs->{$ENV{'DRIVER'}}, 'registered database with dbm');

# 4 get the parent collection
my $col;
my $url = $ENV{'URL'};
$url =~ s/http://;
eval{
	$col = $dbm->getCollection("xmldb:$ENV{'DRIVER'}:$url/db/test");
};
if ($@){
	print $@;
}
ok(ref($col) eq 'XML::DB::Collection', 'got test collection');

# lets find out if the test data has been loaded already

# 5 test collectionManager
my $coll_manager;
eval{
	$resp = $col->listChildCollections();
	my %clist;
	map { $clist{$_} = 1} @{$resp};
	if ($clist{'shakespeare'}){
		# should have been deleted last time round, so shouldnt be here
		$col = $dbm->getCollection("xmldb:$ENV{'DRIVER'}:$url/db/test/shakespeare");
	}
	else{
		$coll_manager = $col->getService('CollectionManager', '1.0');
		$coll_manager->createCollection('shakespeare');
		$col = $dbm->getCollection("xmldb:$ENV{'DRIVER'}:$url/db/test/shakespeare");
	}
};
if ($@){
	print $@;
}
ok(ref($col) eq 'XML::DB::Collection', 'used collection manager');

my $service = 0;
$service = $col->getService('XPathQueryService', '1.0');

# 6 do xpath query on collection
my $resp;
eval{
	$resp = $service->query('//TITLE');
	my $aref = $resp->getIterator();
	my $found = 0;
	foreach(@{$aref}){ 
		if ($_->getContent() =~ /The Tragedy of Hamlet, Prince of Denmark/){
			$found = 1;
			last;
		}
	}
	if (! $found){
		my $play;
		my $file = 'data/hamlet.xml';
		open (IN, $file);
		while(<IN>){
			$play .= $_;
		}
		my $resource;
		$resource = $col->getResource('hamlet');
		$resource->setContent($play);
		$col->storeResource($resource);
		$resp = $service->query('//TITLE');
	}
};
if ($@){
	print $@;
}
my ($aref, $found);
if (ref($resp) =~ 'XML::DB::ResourceSet'){
	$aref = $resp->getIterator();
	foreach(@{$aref}){ 
		if ($_->getContent() =~ /The Tragedy of Hamlet, Prince of Denmark/){
			$found = 1;
			last;
		}
	}
}
ok($found, 'test collection queried');

# 7 get ResourceSet
eval{
	 $resp = $service->query('//SPEECH[SPEAKER="HAMLET"]');
};
if ($@){
  print $@;
}
my $result = 0;
if (ref($resp) =~ 'XML::DB::ResourceSet'){
	$result = $resp->getIterator()->[0]->getContent();
}
ok($result, "got speeches");

# 8 use xupdate
my $xupdate = '<xu:modifications version="1.0" xmlns:xu="http://www.xmldb.org/xupdate"><xu:update select="/PLAY/TITLE[1]">The Tragedy of Hamlet, Prince of France</xu:update></xu:modifications>';
$found = 0;	
eval{
	$col = $dbm->getCollection("xmldb:$ENV{'DRIVER'}:$url/db/test/shakespeare");
	$service2 = $col->getService('XUpdateQueryService', '1.0');
	$service2->updateResource('hamlet', $xupdate);
	$resp = $service->query('/PLAY//TITLE');
	my $aref = $resp->getIterator();
	foreach(@{$aref}){
#		print $_->getContent(); 
		if ($_->getContent() =~ /The Tragedy of Hamlet, Prince of France/){
			$found = 1;
			last;
		}
	}
};
if ($@){ 
	print $@;
}
ok($found, 'xupdate worked on resource');


# 9 remove collection
eval{
	$col = $dbm->getCollection("xmldb:$ENV{'DRIVER'}:$url/db/test");
	$coll_manager = $col->getService('CollectionManager', '1.0');
	$resp = $coll_manager->removeCollection('shakespeare');
};
if ($@){ 
	print $@;
}
ok(! $@, 'removed collection');

# 10 shouldnt be able to store resources in root collection
$url = $ENV{'URL'};
$url =~ s/http://;
eval{
	$col = $dbm->getCollection("xmldb:$ENV{'DRIVER'}:$url/db");
};
if ($@){
	print $@;
}
# get new (empty) resource
my $resource = 0;
eval{
	$resource = $col->getResource($id);
};
if ($@){
	print $@;
}
# put some data in the Resource
my $doc = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<data>some test</data>";
$resource->setContent($doc);
my $ok = 0;
eval{
	$resource = $col->storeResource($resource);
};
if ($@){
	die $@ unless ($@ =~ /VENDOR_ERROR/);
	$ok = 1;
}
ok($ok, 'cant store in /db');

#11 shouldnt try to read resources from /db
$resp =0;
eval{
	$resp = $col->getResourceCount();
};
if ($@){
	print $@;
}
$resp2 = 0;
eval{
	$resp2 = $col->listResources();
};
if ($@){
	print $@;
}
ok(! $resp && ! defined $resp2->[0], 'cant read resources from /db');

	
