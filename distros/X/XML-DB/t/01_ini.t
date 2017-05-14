# t/01_ini.t; 
# test the driver without the API

use Test::More tests => 13;

# 1 load
my $class = ucfirst(lc($ENV{'DRIVER'}));
eval 'require XML::DB::Database::'.$class;
my($loaded) = 1;
ok($loaded, "Checking ".$class.".pm exists");

# 2 create db
my $db = new XML::DB::Database($ENV{'DRIVER'});
$db->setURI($ENV{'URL'});
ok(ref($db), "Creating new $ENV{'DRIVER'} driver");
			
					
# 3 create collection
$resp = 0;
eval { # try
	$resp = $db->createCollection('/db', 'perltest');
	};
if ($@){ # catch
	print $@;
}
ok($resp, 'Created collection');


# 4 list child collections
$resp = 0;
eval{
	$resp = $db->listChildCollections('/db');
};
if ($@){ # catch
	print $@;
}
my %clist;
map { $clist{$_} = 1} @{$resp};
ok($clist{'perltest'}, 'listed child collection');

# 5 drop collection
eval{
	$resp = $db->dropCollection('/db/perltest');
};
if ($@){ # catch
	print $@;
}
ok($resp == 1, 'dropped collection');

# 6 insert document
eval { # try
	$resp = $db->createCollection('/db', 'perltest');
	};
if ($@){ # catch
	print $@;
}
my $doc = "<?xml version=\"1.0\"?>\n<test>hello</test>";
$resp = 0;
eval { # try
	$resp = $db->insertDocument('/db/perltest', $doc, 'testlet.xml');
	};
if ($@){ # catch
	print $@;
}
my $id = 'testlet.xml';
ok($resp, "inserted document");

# die;
# 7 get document count
$resp = 0;
eval { # try
	$resp = $db->getDocumentCount('/db/perltest');
	};
if ($@){ # catch
	print $@;
}
ok($resp == 1, "gets document count");

# 8 get document 
$resp = 0;
eval { # try
	$resp = $db->getDocument('/db/perltest', $id);
	};
if ($@){ # catch
	print $@;
}
ok($resp =~ /hello/, "fetches document back");

# 9 create a unique oid
$resp = 0;
eval { # try
	$resp = $db->createId('/db/perltest');
	};
if ($@){ # catch
	print $@;
}
ok($resp && ($resp ne $id), "created id");

# 10 list documents
$resp = 0;
eval{
	$resp = $db->listDocuments('/db/perltest');
};
if ($@){ # catch
	print $@;
}
ok($resp->[0] eq $id, 'listed document');

# 11 query document
$resp = 0;
my $namespace = {test=>'http://test'}; # dummy
eval{
	$resp = $db->queryDocument('/db/perltest', 'XPath', '/test', $namespace, $id);
};
if ($@){ # catch
	print $@;
}
ok($resp =~ /hello/, 'queried document'); 

# 12 query collection
$resp = 0;
eval{
	$resp = $db->queryCollection('/db/perltest', 'XPath', '/test', $namespace);
};
if ($@){ # catch
	print $@;
}
ok($resp =~ /hello/, 'queried collection'); 

# 13 drop document
$resp = 0;
eval{
	$resp = $db->removeDocument('/db/perltest', $id);
};
if ($@){ # catch
	print $@;
}
$resp = 0;
eval{
	$resp = $db->listDocuments('/db/perltest');
};
if ($@){ # catch
	print $@;
}
ok(! $resp->[0], 'removed document');

##### tidy up ################
eval{
	$resp = $db->dropCollection('/db/perltest');
};
if ($@){ # catch
	print $@;
}
