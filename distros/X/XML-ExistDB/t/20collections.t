#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;

use XML::eXistDB::RPC;

use Data::Dumper;
$Data::Dumper::Indent = 1;

my $uri = $ENV{XML_EXIST_TESTDB}
    or plan skip_all => 'define XML_EXIST_TESTDB to run tests';

plan tests => 38;

my $db = XML::eXistDB::RPC->new(destination => $uri);
isa_ok($db, 'XML::eXistDB::RPC', "rpc to $uri");

my ($rc, $desc) = $db->getCollectionDesc;
cmp_ok($rc, '==', 0, 'got description');
isa_ok($desc, 'HASH', '... with data');
is($desc->{name}, '/db');
is($desc->{owner}, 'admin');

($rc, my @subs) = $db->subCollections;
cmp_ok($rc, '==', 0, 'got sub-collections');

my $collname = "$desc->{name}/test-coll";
my $system   = "$desc->{name}/system";

my %subs = map { $_ => 1 } @subs;

ok($subs{$system}, "found $system");

($rc, my $creation) = $db->collectionCreationDate;
cmp_ok($rc, '==', 0, 'got creation date');
like($creation, qr/^(19[0-9][0-9]|20[0-9][0-9])-/ ,"check creation: $creation");

($rc, my $success) = $db->createCollection($collname);
cmp_ok($rc, '==', 0, "created collection $collname");
ok($success);

($rc, my @subs2) = $db->subCollections;
cmp_ok($rc, '==', 0, 'got sub-collections again');
my %subs2 = map { $_ => 1 } @subs2;
ok($subs2{$system});
ok($subs2{$collname});

($rc, my @subs3) = $db->subCollections($collname);
cmp_ok($rc, '==', 0, "got subs of $collname");
cmp_ok(scalar @subs3, '==', 0, 'no subs for sub');

($rc, my $testdb) = $db->getCollectionDesc($collname);
cmp_ok($rc, '==', 0, "get descr of $collname");
is($testdb->{name}, $collname);
is($testdb->{owner}, 'guest');

my %config = (validation => {mode => 'yes'});
($rc, $success) = $db->configureCollection($collname, \%config);

($rc, my $descr) = $db->describeCollection($collname);
cmp_ok($rc, '==', 0, "describe collection $collname");

# only diff between describeCollection and getCollectionDesc
delete $testdb->{documents};
is_deeply($testdb, $descr);

($rc, my $has) = $db->hasCollection($collname);
cmp_ok($rc, '==', 0, "has collection $collname");
cmp_ok($has, '==', 1);

my $collnot = "$collname-not-exists";
($rc, $has) = $db->hasCollection($collnot);
cmp_ok($rc, '==', 0, "has not collection $collnot");
cmp_ok($has, '==', 0);

# ERROR?  method seems not to use parameter
($rc, my $perms) = $db->describeCollectionPermissions($collname);
cmp_ok($rc, '==', 0, "permissions for $collname");
is_deeply($perms, {}, "no permissions found (exist 1.4 bug!)");

($rc, $perms) = $db->describeCollectionPermissions('/db');

TODO: {

local $TODO = "Exist 1.4 server crashes";

cmp_ok($rc, '==', 0, "permissions for top-level");

warn Dumper $db->trace->{request}->as_string;
warn Dumper $db->trace->{response}->as_string;

if(ref $perms)
{  is_deeply($perms->{$system}
      , {user => 'admin', group => 'dba',   mode => 504});
   is_deeply($perms->{$collname}
      , {user => 'guest', group => 'guest', mode => 493});
}
else
{   # produce error on server bug
    is($perms, 'expected an answer');
    ok(1);  # no second test
}

   };  # END TODO

($rc, $success) = $db->reindexCollection($collname);
cmp_ok($rc, '==', 0, "reindex");
cmp_ok($success, '==', 1);

($rc, $success) = $db->removeCollection($collname);
cmp_ok($rc, '==', 0, "remove");
cmp_ok($success, '==', 1);

($rc, my @subs4) = $db->subCollections;
cmp_ok($rc, '==', 0, 'check_removal');
my %subs4 = map { $_ => 1 } @subs4;
ok(!$subs4{collname});

($rc, my $acml) = $db->isXACMLEnabled;
cmp_ok($rc, '==', 0, 'ACML');
cmp_ok($acml, '==', 0);

#warn $db->trace->{response}->as_string;

# Still untested:
# copyCollection($from, $to)
# copyCollection($from, $coll, $subcoll)
# moveCollection($from, $to)
# moveCollection($from, $coll, $subcoll)
