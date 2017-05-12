#!/usr/bin/perl
# vim: set filetype=perl:
# COVER:ACL.pm
use strict;
use warnings;
use Term::ReadKey;
use Data::Dumper;

use Test::More tests => 90;

BEGIN {
    use_ok( 'Tivoli::AccessManager::Admin' );
}

ReadMode 2;
print "sec_master password: ";
my $pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $pd = Tivoli::AccessManager::Admin->new( password => $pswd);
my $acl = Tivoli::AccessManager::Admin::ACL->new( $pd, name => 'monkey' );
my ($resp,@temp);
my $limit = "Trx";

isa_ok( $acl, 'Tivoli::AccessManager::Admin::ACL' );
is( $acl->name, 'monkey', "Its a monkey" );

print "\nTESTING list\n";
$resp = $acl->list;
ok( ($resp->isok and $resp->value), "Listed ACLs as an instance method");
my @listacl = $resp->value;

$resp = Tivoli::AccessManager::Admin::ACL->list($pd);
ok( $resp->isok, "Listed ACLs as a class method");
is_deeply( [$resp->value], \@listacl, "and got the same list as before");

print "\nTESTING new\n";
$acl = Tivoli::AccessManager::Admin::ACL->new( $pd );
isa_ok( $acl, 'Tivoli::AccessManager::Admin::ACL', "Created an ACL with no name" );

$acl = Tivoli::AccessManager::Admin::ACL->new( $pd, 'monkey1' );
isa_ok( $acl, 'Tivoli::AccessManager::Admin::ACL', "Created another monkey" );

print "\nTESTING create\n";
$resp = $acl->create();
ok( $resp->value, "Create the monkey" ) or diag($resp->messages);

$resp = $acl->create();
is( $resp->iswarning, 1, "Can only create one monkey" );

$resp = $acl->exist;
is( $resp, 1, "The monkey exists!" );

print "\nTESTING attributes\n";
$resp = $acl->attributes( add => { evil => 0, 
				  monkey => [ qw/1 2 3/],
			        } 
		       );
is ( $resp->isok, 1, "Added some attributes" ) or diag($resp->messages);

$resp = $acl->attributes;
is_deeply( scalar($resp->value), { monkey => [qw/1 2 3/], 
			   evil => [0] }, 
	    "All the values are there" ) or diag($resp->messages );

$resp = $acl->attributes( remove => { monkey => 3 } );
is( $resp->isok, 1, "Deleted a value" ) or diag( $resp->messages );

$resp = $acl->attributes;
is_deeply( scalar($resp->value), { monkey => [1,2], evil => [0] }, "The value is gone" ) or
    diag($resp->messages);

$resp = $acl->attributes( removekey => ["evil"] );
is( $resp->isok, 1, "Deleted a key" ) or diag( $resp->messages );

$resp = $acl->attributes;
is_deeply( scalar($resp->value), { monkey => [1,2] }, "Evil has been deleted" ) or
    diag($resp->messages);

$resp = $acl->attributes( remove => { monkey => [1,2] } );
is( $resp->isok, 1, "Deleted multivalues" ) or diag( $resp->messages );
is_deeply( scalar($resp->value), {}, "All key/values are gone" ) or
    diag($resp->messages);

print "\nTESTING ACL group commands\n";
$resp = $acl->user( name => 'sec_master' );
my $perms = $resp->value;

$resp = $acl->group( name => 'iv-admin', perms => $perms );
is( $resp->value, $perms, "Adding iv-admin to the monkey" );

$resp = $acl->group( name => 'iv-admin', perms => $limit );
is($resp->value,$limit,"Adding iv-admin with different perms to the monkey");

$resp = $acl->group( name => 'iv-admin' );
is($resp->value,$limit,"Verified iv-admin permissions in the monkey");

$resp = $acl->listgroups;
is( $resp->value, 'iv-admin', "iv-admin in the monkey" );

$resp = $acl->group( name => 'iv-admin', perms => 'remove' );
is( $resp->value, '', "Removing iv-admin from the monkey" );

$resp = $acl->listgroups;
is( $resp->value, 'none', "No groups in the monkey" );

print "\nTESTING ACL users commands\n";
$resp = $acl->user( name => 'mik', perms => $limit );
is( $resp->value, $limit, "Adding mik back to the monkey" );

$resp = $acl->user( name => 'mik', perms => 'remove' );
ok( $resp->isok, "Removing mik" ) or diag( $resp->messages );
is( $resp->value, '', "Removed mik from the monkey" );

$resp = $acl->listusers;
is($resp->value, 'sec_master', "Only sec_master left");

#I need something to have full control before I can removed sec_master
$resp = $acl->group( name => 'iv-admin', perms => $perms );
$resp = $acl->user( name => 'sec_master', perms => 'remove' );
$resp = $acl->listusers;
is($resp->value, 'none', "And then there were none");

$resp = $acl->user( name => 'sec_master', perms => $perms );
is( $resp->value, $perms, "Adding sec_master back to the monkey" ) or 
	diag( $resp->messages );

print "\nTESTING permissions for anyother\n";
$resp = $acl->anyother( perms => "TcmdbsvaBRl" );
is( $resp->value, $perms, "Anyother given all access to the monkey");

$resp = $acl->anyother( perms => "" );
is( $resp->value, '', "Anyother denied all access to the monkey");

$resp = $acl->anyother( perms => $limit );

$resp = $acl->anyother( perms => 'remove' );
is( $resp->value, '', "Anyother access removed to the monkey");

$resp = $acl->anyother( perms => $limit );
is( $resp->value, $limit, "Anyother given Trx access to the monkey");

$resp = $acl->anyother;
is( $resp->value, $limit, "Anyother has Trx access to the monkey");

print "\nTESTING permissions for unauth\n";
$resp = $acl->unauth( perms => [] );
is( $resp->value, undef, "unauth denied all access to the monkey");

$resp = $acl->unauth( perms => $limit );
is( $resp->value, $limit, "unauth given Trx access to the monkey");

$resp = $acl->unauth;
is( $resp->value, $limit, "unauth has Trx access to the monkey");

$resp = $acl->unauth( perms => 'remove' );
is( $resp->value, '', "unauth given Trx access to the monkey");

$resp = $acl->description( "I am a good little monkey");
is( $resp->value, 'I am a good little monkey', "Set the description" );

$resp = $acl->description( description => "I am a curious little monkey");
is( $resp->value, 'I am a curious little monkey', "Set the description another way" );

$resp = $acl->description( silly => "I am a silly little monkey");
is($resp->value, 'I am a curious little monkey', "Ignored a silly hash key");

$resp = $acl->delete;
ok( $resp->isok, "Deleted the monkey" );

print "\nTESTING find\n";

$acl = Tivoli::AccessManager::Admin::ACL->new( $pd, 'default-webseal' );
$resp = $acl->find;
is( $resp->isok, 1, 'The ACL find wrapper worked' );

$acl = Tivoli::AccessManager::Admin::ACL->new( $pd, 'monkey1');

print "\nTESTING brokeness\n";

$resp = $acl->listgroups;
is($resp->isok, 0, "Could not call finduser on a non-existent ACL");

$resp = $acl->listusers;
is($resp->isok, 0, "Could not call finduser on a non-existent ACL");

$resp = $acl->listgroups;
is($resp->isok,0, "Could not list the groups of a non-existent ACL");

$resp = $acl->listusers;
is($resp->isok,0, "Could not list the users of a non-existent ACL");

$resp = $acl->unauth( perms => 'Trx' );
is($resp->isok,0, "Could not set the unauthenticated access of a non-existent ACL");

$resp = $acl->anyother( perms => 'Trx' );
is($resp->isok,0, "Could not set the anyother access of a non-existent ACL");

$resp = $acl->group( name => 'iv-admin', perms => 'Trx' );
is($resp->isok,0, "Could not set group access of a non-existent ACL");

$resp = $acl->user( name => 'sec_master', perms => 'Trx' );
is($resp->isok,0, "Could not set user access of a non-existent ACL");

$resp = $acl->attributes;
is($resp->isok,0, "Could not access the attributes of a non-existent ACL");

$resp = $acl->attributes( add => { evil => 0, 
				  monkey => [ qw/1 2 3/],
			        } 
		       );
is($resp->isok,0, "Could not add attributes to a non-existent ACL");

$resp = $acl->attributes( remove => { monkey => 3 } );
is($resp->isok,0, "Could not remove attributes from a non-existent ACL");

print "\nTESTING broken new\n";
$acl = Tivoli::AccessManager::Admin::ACL->new();
is($acl, undef, 'No parameters whatsoever failed');

$acl = Tivoli::AccessManager::Admin::ACL->new( 'wikiwikiwik' );
is($acl, undef, 'No Tivoli::AccessManager::Admin::Context failed');

$acl = Tivoli::AccessManager::Admin::ACL->new( $pd, 'monkey1', 'monkey2', 'monkey3' );
is( $acl, undef, "Too many parameters failed");

$acl = Tivoli::AccessManager::Admin::ACL->new( $pd, name => 0 );
is($acl->exist, 0, "Unnamed ACL worked");

print "\nTESTING broken create\n";
$resp = Tivoli::AccessManager::Admin::ACL->create();
is($resp->isok, 0, 'No parameters whatsoever failed');

$acl = Tivoli::AccessManager::Admin::ACL->create( 'wikiwikiwik' );
is($resp->isok, 0, 'No Tivoli::AccessManager::Admin::Context failed');

$resp = Tivoli::AccessManager::Admin::ACL->create( $pd, 'monkey1' );
is( $resp->isok, 1, "Created another monkey" ) or diag($resp->messages);

$acl = $resp->value;
isa_ok( $acl, 'Tivoli::AccessManager::Admin::ACL' );
is( $acl->name, 'monkey1', "Its an Evil monkey" );

print "\nTESTING broken permissions\n";
$resp = $acl->anyother( perms => [qw/smoking/] );
is( $resp->isok, 0, "Evil monkey tried smoking anyother and was denied");

$resp = $acl->anyother( perms => 'smoking' );
is( $resp->isok, 0, "Evil monkey tried smoking anyother and was denied again");

$resp = $acl->unauth( perms => 'smoking' );
is( $resp->isok, 0, "Evil monkey tried smoking unauth and was denied");

$resp = $acl->user( name => 'sec_master',
		    perms => 'smoking' );
is( $resp->isok, 0, "Evil monkey tried smoking sec_master and was denied");

$resp = $acl->group( name => 'iv-admin',
		    perms => 'smoking' );
is( $resp->isok, 0, "Evil monkey tried smoking iv-admin and was denied");

$resp = $acl->user( perms => 'smoking' );
is( $resp->isok, 0, "Evil monkey didn't tell which user");

$resp = $acl->group( perms => 'smoking' );
is( $resp->isok, 0, "Evil monkey didn't tell which group");

print "\nTESTING odd number of parameters\n";
$resp = $acl->unauth( 'foo' );
is( $resp->isok, 0, 'Odd number of parameters to unauth failed');

$resp = $acl->anyother( 'foo' );
is( $resp->isok, 0, 'Odd number of parameters to anyother failed');

$resp = $acl->group( 'foo' );
is( $resp->isok, 0, 'Odd number of parameters to group failed');

$resp = $acl->user( 'foo' );
is( $resp->isok, 0, 'Odd number of parameters to user failed');

$resp = $acl->attributes( 'foo' );
is( $resp->isok, 0, 'Odd number of parameters to attributes failed');

$resp = $acl->description( qw/one two three/ );
is( $resp->isok, 0, 'Odd number of parameters to description failed');


print "\nTESTING description\n";
$resp = $acl->description;
is( $resp->value, 'none', "The Evil monkey has no description");

print "\nTESTING evil\n";

$acl->{exist} = 0;
$resp = $acl->create();
is($resp->isok, 0, "Could not create an ACL twice");

$resp = $acl->delete;
ok( $resp->isok, "Deleted the Evil monkey" );

# This is not really a bright idea....
$acl->{exist} = 1;

$resp = $acl->delete;
is($resp->isok, 0, "Could not delete after evil");

$acl->{exist} = 1;
$resp = $acl->description('pure');
is($resp->isok, 0, "Could not describe evil");

print "\nTesting broken attributes\n";
$resp = $acl->attributes( add => { monkey => 1 } );
is($resp->isok, 0, "Could not add scalar evil");

$resp = $acl->attributes( add => { monkey => [ qw/1 2 3/] } );
is($resp->isok, 0, "Could not add array evil");

$resp = $acl->attributes( remove => { monkey => 1 } );
is($resp->isok, 0, "Could not delete scalar evil");

$resp = $acl->attributes( remove => { monkey => [qw/1 2/] } );
is($resp->isok, 0, "Could not delete array evil");

$resp = $acl->attributes();
is_deeply([$resp->value], [], "evil has no attributes") or diag(Dumper($resp,$acl));

$resp = $acl->attributes( remove => { foo => [qw/bar baz/] } );
is( $resp->isok, 0, "Could not remove attribute values from evil");

$resp = $acl->attributes( removekey => [qw/foo/] );
is( $resp->isok, 0, "Could not remove attribute keys from evil");


END {
    ReadMode 0;
}
