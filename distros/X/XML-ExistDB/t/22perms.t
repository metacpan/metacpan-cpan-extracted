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

plan tests => 31;

my $db = XML::eXistDB::RPC->new(destination => $uri);
isa_ok($db, 'XML::eXistDB::RPC', "rpc to $uri");

my $collname = '/db/test-perms';

$db->removeCollection($collname);  # result from test crash

my ($rc, $success) = $db->createCollection($collname);
cmp_ok($rc, '==', 0, "created collection $collname");
ok($success);

($rc, my @res) = $db->listResources($collname);
cmp_ok($rc, '==', 0, "list resources in $collname");
cmp_ok(scalar @res, '==', 0, "new collection is empty");

my $doc1 = "$collname/doc.xml";
my $doc1xml = '<doc><a><b>3</b><c/></a></doc>';
($rc, my $ok) = $db->uploadDocument($doc1, $doc1xml);
cmp_ok($rc, '==', 0, "upload $doc1");
cmp_ok($ok, 'eq', 1);

($rc, my $perms) = $db->describeResourcePermissions($doc1);
cmp_ok($rc, '==', 0, "described perms $doc1");
is_deeply($perms, { owner => 'guest', group => 'guest', permissions => 493 });

($rc, $perms) = $db->listDocumentPermissions($collname);
cmp_ok($rc, '==', 0, "described perms $collname");
is_deeply($perms, { 'doc.xml' => [ guest => guest => 493 ] } );

($rc, my $user) = $db->describeUser('guest');
cmp_ok($rc, '==', 0, "described user guest");
is_deeply($user, { groups => [ 'guest' ], name => 'guest' });

my %expusers =
 ( admin => { name => 'admin', groups => [ 'dba' ] }
 , guest => { name => 'guest', groups => [ 'guest' ] }
 );

($rc, my $users) = $db->listUsers;
cmp_ok($rc, '==', 0, 'list users');
is_deeply($users, \%expusers);

($rc, my @groups) = $db->listGroups;
cmp_ok($rc, '==', 0, 'list groups');
is_deeply( [sort @groups], [ 'dba', 'guest' ] );

my $home = "$collname/markov";
($rc, $ok) = $db->setUser('markov', 'testpw', 'guest', $home);
cmp_ok($rc, '!=', 0, 'cannot add user: no perms');

$db->login(admin => 'xyz');

($rc, $ok) = $db->setUser('markov', 'testpw', 'guest', $home);
cmp_ok($rc, '==', 0, 'now admin');
cmp_ok($ok, 'eq', 1);

($rc, $perms) = $db->describeCollectionPermissions($home);
cmp_ok($rc, '==', 0, 'user markov home permissions');

TODO: {

local $TODO = "expect some info to be returned";
warn Dumper $perms;
ok(0);

      }; # END TODO

($rc, $users) = $db->listUsers;
cmp_ok($rc, '==', 0, 'list users');
$expusers{markov} = { name => 'markov', groups => [ 'guest' ], home => $home };
is_deeply($users, \%expusers);

$db->login(markov => 'testpw');
($rc, $users) = $db->listUsers;
cmp_ok($rc, '==', 0, 'can we do anything with this permissions?');

$db->login(admin => 'xyz');

($rc, $ok) = $db->removeUser('markov');
cmp_ok($rc, '==', 0, 'removed markov');
cmp_ok($ok, 'eq', 1);

($rc, $ok) = $db->removeCollection($collname);
cmp_ok($rc, '==', 0, 'remove collection');
cmp_ok($ok, 'eq', 1);

($rc, my $c) = $db->describeCollection;
cmp_ok($rc, '==', 0, 'really gone?');
ok(!grep {$_ eq basename $collname} @{$c->{collections}});

