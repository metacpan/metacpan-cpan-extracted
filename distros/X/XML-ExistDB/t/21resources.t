#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;

use XML::eXistDB::RPC;
use File::Basename 'basename';

use Data::Dumper;
$Data::Dumper::Indent = 1;

my $uri = $ENV{XML_EXIST_TESTDB}
    or plan skip_all => 'define XML_EXIST_TESTDB to run tests';

plan tests => 48;

my $db = XML::eXistDB::RPC->new(destination => $uri);
isa_ok($db, 'XML::eXistDB::RPC', "rpc to $uri");

my $collname = '/db/test-res';

$db->removeCollection($collname);  # result from test crash

my ($rc, $success) = $db->createCollection($collname);
cmp_ok($rc, '==', 0, "created collection $collname");
ok($success);

($rc, my @docs) = $db->listResources($collname);
cmp_ok($rc, '==', 0, "list empty collection $collname");
cmp_ok(scalar @docs, '==', 0, 'no docs yet');

### add document

my $doc1 = "$collname/doc1.xml";
($rc, $success) = $db->uploadDocument($doc1, "<doc><a/></doc>");
cmp_ok($rc, '==', 0, 'upload first document');

($rc, @docs) = $db->listResources($collname);
cmp_ok($rc, '==', 0, "first doc in $collname");
cmp_ok(scalar @docs, '==', 1, 'one doc in list');
is($docs[0], 'doc1.xml');

($rc, my $count) = $db->countResources($collname);
cmp_ok($rc, '==', 0, "first count");
cmp_ok($count, '==', 1);

($rc, my $details) = $db->describeResource($doc1);
#warn Dumper $details;
cmp_ok($rc, '==', 0, "describe doc1");
cmp_ok(keys %$details, '>', 5);
is($details->{type}, 'XMLResource');
is($details->{group}, 'guest');

($rc, my @ts) = $db->listResourceTimestamps($doc1);
cmp_ok($rc, '==', 0, "document timestamps");
cmp_ok(scalar @ts, '==', 2);

($rc, my $s) = $db->setDocType($doc1, 'name', 'pub', 'sys');
cmp_ok($rc, '==', 0, "set doctype");
cmp_ok($s, '==', 1);

($rc, my $n, my $pub, my $sys) = $db->getDocType($doc1);
cmp_ok($rc, '==', 0, "get doctype");
is($n, 'name');
is($pub, 'pub');
is($sys, 'sys');

### add binary

my $img = "$collname/fake-img.jpg";
my $fakebin = "ABCDEF";

($rc, $success) = $db->uploadBinary($img, $fakebin, 'image/jpeg', 0);
cmp_ok($rc, '==', 0, "added binary to $collname");
cmp_ok($success, 'eq', 1);

($rc, @docs) = $db->listResources($collname);
cmp_ok($rc, '==', 0, "binaries not shown");
cmp_ok(scalar @docs, '==', 2, 'now two element in the list');
@docs = sort @docs;
is($docs[0], 'doc1.xml');
is($docs[1], 'fake-img.jpg');

($rc, $count) = $db->countResources($collname);
cmp_ok($rc, '==', 0, "second count");
cmp_ok($count, '==', 2);

($rc, $details) = $db->describeResource($img);
cmp_ok(keys %$details, '>', 5);
is($details->{type}, 'BinaryResource');
is($details->{group}, 'guest');
is($details->{'content-length'}, length $fakebin);

#($rc, $details) = $db->describeCollection($collname, documents => 1);
#warn Dumper $details;

($rc, @ts) = $db->listResourceTimestamps($img);
cmp_ok($rc, '==', 0, "binary timestamps");
cmp_ok(scalar @ts, '==', 2);

### download document

($rc, my $downdoc) = $db->downloadDocument($doc1, indent => 'no');
cmp_ok($rc, '==', 0, "download no-indent");
is($downdoc, "<doc><a/></doc>");

($rc, $downdoc) = $db->downloadDocument($doc1, indent => 'yes');
cmp_ok($rc, '==', 0, "download indented");
is($downdoc, "<doc>\n    <a/>\n</doc>");

### download binary

($rc, my $downbin) = $db->downloadBinary($img);
cmp_ok($rc, '==', 0, "download binary");
is($downbin, $fakebin, "received what was uploaded");

### unique names

($rc, my $id1) = $db->uniqueResourceName($collname);
cmp_ok($rc, '==', 0, "resource-id 1: $id1");

($rc, my $id2) = $db->uniqueResourceName($collname);
cmp_ok($rc, '==', 0, "resource-id 2: $id2");

isnt($id1, $id2);

### clean-up

($rc, $success) = $db->removeCollection($collname);
cmp_ok($rc, '==', 0, "remove collection $collname");
cmp_ok($success, 'eq', 1);

