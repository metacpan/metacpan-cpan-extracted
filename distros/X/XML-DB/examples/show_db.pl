#!/usr/bin/perl
use strict;
use XML::DB::DatabaseManager;

my $XMLDB_DRIVER = 'Xindice';
my $DRIVER_URL = 'http://localhost:4080';
#my $XMLDB_DRIVER = 'eXist';
#my $DRIVER_URL = 'http://localhost:8081';


# return the Collections and their resources for the whole database as an 
# XML document in tree form

my $dbm = new XML::DB::DatabaseManager();
$dbm->registerDatabase($XMLDB_DRIVER);
my $col = $dbm->getCollection("xmldb:$XMLDB_DRIVER:$DRIVER_URL/db");
my %h;

getChildren($col, \%h);
printChildren(\%h, '');

# create a tree of hashes
sub getChildren{
	my ($col, $hr) = @_;

	eval{
		my $resources = $col->listResources();
		$hr->{'_resource'} = $resources;
	};
	eval{
		my $list = $col->listChildCollections();
		for my $colname(@{$list}){
			if ($colname !~ /System/i){
				my $col2 = $col->getChildCollection($colname);
				my %newh;
				$hr->{$colname} = getChildren($col2, \%newh);
			}
		}
	};
	if ($@){
		print $@;
	}
  return $hr;
}

# unpack the tree of hashes as XML
sub printChildren{
	my ($hr, $inset) = @_;
	for my $key (keys %{$hr}){
		if ($key =~ /_resource$/){
			for my $doc(@{$hr->{$key}}){
				print "$inset<resource>$doc</resource>\n";
			}
		}
		else{
			print "$inset<collection>\n";
			print "$inset<name>$key</name>\n";
			printChildren($hr->{$key}, $inset."\t");
			print "$inset</collection>\n";
		}
	}
}  	
