#!/usr/bin/perl
# vim: set filetype=perl:
# COVER:Domain.pm
use strict;
use warnings;
use Term::ReadKey;
use Data::Dumper;

use Test::More tests => 38;

BEGIN {
    use_ok('Tivoli::AccessManager::Admin');
}

my ($resp,$pswd);
ReadMode 2;
print "sec_master password: ";
$pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $pd  = Tivoli::AccessManager::Admin->new( password => $pswd );

print "\nTESTING creates and deletes\n";

my $dom = Tivoli::AccessManager::Admin::Domain->new( $pd,
				   name => 'test',
				   admin => 'monkey',
				   description => 'Test domain',
				 );
isa_ok( $dom, 'Tivoli::AccessManager::Admin::Domain' );
$resp = $dom->create;
is( $resp->isok, 0, "Couldn't create a domain w/o a password" ) 
    or diag($resp->messages);

$resp = $dom->create(password => 'f00b4r');
is( $resp->isok, 1, "Created a domain" ) or diag($resp->messages);

$resp = $dom->create(password => 'f00b4r');
is( $resp->isok, 0, "Couldn't create an existing domain" ) 
    or diag($resp->messages);

$resp = $dom->delete( registry => 1 );
is( $resp->isok, 1, "Deleted the domain from the registry" )
    or diag($resp->messages);

$resp = Tivoli::AccessManager::Admin::Domain->create( name => 'test',
				    admin => 'monkey',
				    password => 'f00b4r',
				    description => 'Test domain',
				);
is( $resp->isok, 0, "Couldn't create a domain w/o a context" )
    or diag($resp->messages );

$resp = Tivoli::AccessManager::Admin::Domain->create( $pd, 
				    password => 'f00b4r',
				    name => 'test',
				    description => 'Test domain',
				    admin => 'monkey' );
is( $resp->isok, 1, "Created a domain" )
    or diag($resp->messages );
$dom  = $resp->value;

$resp = $dom->delete( );
is( $resp->isok, 1, "Deleted the domain - but not from the registry" )
    or diag($resp->messages);

$dom = Tivoli::AccessManager::Admin::Domain->new( $pd,
				   name => 'test',
				   description => 'Test domain',
				 );
$resp = $dom->create(password => 'f00b4r');
is( $resp->isok, 0, "Couldn't create a domain w/o an admin" );

$resp = $dom->create(admin => 'monkey', password => 'f00b4r');
is( $resp->isok, 1, "Created a domain by sending the admin" )
    or diag($resp->messages);

$resp = $dom->delete(qw/one two three/);
is($resp->isok,0,"Could not delete domain with an odd number of parameters");

$resp = $dom->delete(1);
is($resp->isok, 1, "Deleted domain w/o a hash");

$resp = $dom->delete(1);
is($resp->iswarning, 1, "Could not delete an non-existent domain");

$dom = Tivoli::AccessManager::Admin::Domain->new( $pd,
				   admin => 'monkey',
				   description => 'Test domain',
				 );
$resp = $dom->create(password => 'f00b4r');
is( $resp->isok, 0, "Couldn't create a domain w/o a name" );

$resp = $dom->create(name => 'test',password => 'f00b4r');
is( $resp->isok, 1, "Created a domain by sending the admin" )
    or diag(Dumper($dom));

$resp = $dom->delete(sillybastard => 1);
is( $resp->isok, 1, 'Deleted domain w/ an invalid parameter list');

$dom = Tivoli::AccessManager::Admin::Domain->new( $pd,
				   name => 'test',
				   admin => 'monkey',
				 );

$resp = $dom->create(password => 'f00b4r');
is( $resp->isok, 0, "Couldn't create a domain w/o a description" );

$resp = $dom->create(description => 'test domain',password => 'f00b4r');
is( $resp->isok, 1, "Created a domain by sending the description" )
    or diag($resp->messages);

print "\nTESTING description and id\n";

$resp = $dom->description;
is( $resp->value, 'test domain', "Got the original description" )
    or diag($resp->messages);

$resp = $dom->description( description => 'Evil test domain' );
is( $resp->value, 'Evil test domain', "Set the new description" )
    or diag($resp->messages);

$resp = $dom->description( sillybastard => 'More evil test domain' );
is($resp->value, 'Evil test domain', "Invalid param list ignored")
    or diag($resp->messages);
$resp = $dom->description( 'More evil test domain' );
is( $resp->value, 'More evil test domain', "Set the new description" )
    or diag($resp->messages);

$resp = $dom->description( qw/More evil domain/ );
is( $resp->isok, 0, 'Could not send an odd number of parameters')
    or diag($resp->messages);

is( $dom->name, 'test', "Got the domain name back" );

print "\nTESTING list\n";

$resp = Tivoli::AccessManager::Admin::Domain->list;
is( $resp->isok, 0, "Couldn't call list w/o context" );


$resp = Tivoli::AccessManager::Admin::Domain->list($pd);
is( $resp->isok, 1, "Called list as a class method" )
    or diag($resp->messages);
my @list = $resp->value;

$resp = $dom->list;
is( $resp->isok, 1, "Called list as an instance method" ) 
    or diag($resp->messages);

is_deeply( [$resp->value], \@list, "Got the same list back from both" )
    or diag( Dumper(\@list, $resp->value) );

print "\nTESTING Broken things\n";
my $olddom = Tivoli::AccessManager::Admin::Domain->new( $pd,
				   name => 'test1',
				   admin => 'monkey',
				   description => 'Test domain',
				 );
$resp = $olddom->description;
is($resp->isok, 0, "Couldn't get the description of a non-existing domain");

$resp = $olddom->description( description => 'foobar' );
is($resp->isok, 0, "Couldn't set the description of a non-existing domain");

$olddom = Tivoli::AccessManager::Admin::Domain->new( undef );
is($olddom, undef, 'Failed to init w/ an undefined context');

$olddom = Tivoli::AccessManager::Admin::Domain->new( 'not a context' );
is($olddom, undef, 'Failed to init w/ an undefined context');

$olddom = Tivoli::AccessManager::Admin::Domain->new( $pd, qw/work work work/ );
is($olddom, undef, 'Could not init w/ an odd number of parameters');

$resp = Tivoli::AccessManager::Admin::Domain->create($pd, qw/one two three/);
is($resp->isok, 0, 'Odd number of parameters to create failed');

print "\nTESTING evil\n";
$olddom = Tivoli::AccessManager::Admin::Domain->new( $pd,
				   name => 'test1',
				   admin => 'monkey',
				   description => 'Test domain',
				 );

$resp = $olddom->create(password => 'foobar');
$olddom->{exist} = 0;
$resp = $olddom->create(password => 'foobar');
is( $resp->isok, 0, "Evil create() was stopped");

$olddom->{exist} = 1;
$resp = $olddom->delete(1);
$olddom->{exist} = 1;

$resp = $olddom->description("Evil monkey");
is( $resp->isok, 0, "Evil description() was stopped");

$resp = $olddom->description();
is( $resp->isok, 0, "Evil description() was stopped again");

END {
    $dom->delete(registry => 1 );
    ReadMode 0;
}
