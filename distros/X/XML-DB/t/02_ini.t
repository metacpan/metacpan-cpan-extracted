# t/02_ini.t; 
use Test::More tests => 18;

# create some test collections first
use XML::DB::Database;
my $driver = new XML::DB::Database($ENV{'DRIVER'});
$driver->setURI($ENV{'URL'});

# create some collections to test with
# by using the driver directly

eval { # try
	$driver->createCollection('/db', 'perltest');
	};
if ($@){ # catch
	die $@;
}
eval { # try
	$driver->createCollection('/db/perltest', 'child1');
	};
if ($@){ # catch
	die $@;
}
sleep(5);
eval { # try
	$driver->createCollection('/db/perltest', 'child2');
	};
if ($@){ # catch
	die $@;
}
eval { # try
	$driver->createCollection('/db/perltest/child2', 'grandchild1');
	};
if ($@){ # catch
	die $@;
}


# 1 load
use XML::DB::Collection;
my($loaded) = 1;
ok($loaded, "Checking Collection.pm exists");

# 2 create Collection
my $col = new XML::DB::Collection($driver, '/db/perltest', 'child2');
ok(ref($col), 'Creating new Collection');

# 3 get name
my $resp = 0;
$resp = $col->getName();
ok($resp eq 'child2', 'Retrieved name');

#4 get parent Collection
my $parent;
eval{
	$parent = $col->getParentCollection();
};
if ($@){
	print $@;
}
ok($parent->getName() eq 'perltest', 'gets parent Collection');

#5 get child Collection
my $child;
eval{
	$child = $col->getChildCollection('grandchild1');
};
if ($@){
	print $@;
}
ok($child->getName() eq 'grandchild1', 'gets child Collection');

#6 get child Collection count
$resp = 0;
eval{
	$resp = $col->getChildCollectionCount();
};
if ($@){
	print $@;
}
ok($resp == 1, 'gets child Collection count');

#7 get child Collection list
$resp = 0;
eval{
	$resp = $col->listChildCollections();
};
if ($@){
	print $@;
}
my %clist = ();
map { $clist{$_} = 1} @{$resp};
ok($clist{'grandchild1'}, 'listed child collections');

#8 create new ID
my $id = 0;
eval { # try
	$id = $col->createId();
	};
if ($@){ # catch
	print $@;
}
ok($id, 'Created id');

if (!$id){ $id = 'testlet.xml'; } # for old eXist with no createId 

#9 get new (empty) resource
my $resource = 0;
eval{
	$resource = $col->createResource($id, 'XMLResource');
};
if ($@){
	print $@;
}
ok($resource->{'id'} eq $id, 'created empty resource');

# put some data in the Resource
my $doc = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<data>some test</data>";
$resource->setContent($doc);

#10 store resource in db
eval{
	$resource = $col->storeResource($resource);
};
if ($@){
	print $@;
}
ok(! $@, 'thinks resource stored in db');

#11 count resources in db
$resp =0;
eval{
	$resp = $col->getResourceCount();
};
if ($@){
	print $@;
}
ok($resp == 1, 'counts resources in db');

#12 list resources
$resp = 0;
eval{
	$resp = $col->listResources();
};
if ($@){
	print $@;
}
my %clist;
map { $clist{$_} = 1} @{$resp};
ok($clist{$id}, 'listed Resources');

#13 retrieve resource
$resource = 0;
eval{
	$resource = $col->getResource($id);
};
if ($@){
	print $@;
}
# print "content: ". $resource->getContent() . "\n";
ok($resource->getContent() =~ /some test/i, 'retrieved new resource');

# 14 list services
my $services = $col->getServices();
ok($services->[0] eq 'XPathQueryService', 'got service list');

# 15 get XPath service
my $service = 0;
eval{
	$service = $col->getService('XPathQueryService', '1.0');
};
ok(ref $service, 'Got XPathQueryService');

# 16 do xpath query on collection
## either my xpath is wrong, or there's something wrong with eXist
## here - it finds /data, but not //data. Shouldn't they be the
## same? Either works with Xindice.. Need to check on this
$resp = 0;
eval{
	$resp = $service->query('/data');
};
if ($@){
	print $@;
}
my ($aref, $found);
if (ref($resp) eq 'XML::DB::ResourceSet'){
	$aref = $resp->getIterator();
	foreach(@{$aref}){
		if ($_->getContent() =~ /some test/){
			$found = 1;
			last;
		}
	}
}
ok ($found, 'queried collection via service');

# 17 do xpath query on resource
$resp = 0;
eval{
	$resp = $service->queryResource('/data', $id);
};
if ($@){
	print $@;
}
if (ref($resp) eq 'XML::DB::ResourceSet'){
	$aref = $resp->getIterator();
	foreach(@{$aref}){ 
		if ($_->getContent() =~ /some test/){
			$found = 1;
			last;
		}
	}
}
ok ($found, 'queried resource via service');


#18 remove resource
eval{
	$resource = $col->removeResource($resource);
};
if ($@){
	print $@;
}
$resp = 0;
eval{
	$resp = $col->listResources();
};
if ($@){
	print $@;
}
%clist = ();
map { $clist{$_} = 1} @{$resp};
ok(!defined $clist{$id}, 'removed resource');


tidy($driver);
##### tidy up ################
sub tidy{
	my $db = shift;
print "tidying...\n";
eval{
	$resp = $db->dropCollection('/db/perltest/child1');
};
if ($@){ # catch
	print $@;
}
eval{
	$resp = $db->dropCollection('/db/perltest/child2/grandchild1');
};
if ($@){ # catch
	print $@;
}
eval{
	$resp = $db->dropCollection('/db/perltest/child2');
};
if ($@){ # catch
	print $@;
}
eval{
	$resp = $db->dropCollection('/db/perltest');
};
if ($@){ # catch
	print $@;
}
}
