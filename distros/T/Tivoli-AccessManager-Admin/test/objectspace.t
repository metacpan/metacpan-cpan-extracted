#!/usr/bin/perl 
# vim: set filetype=perl:
# COVER:Objectspace.pm
use strict;
use warnings;
use Term::ReadKey;

use Test::More tests => 26;

use Data::Dumper;

BEGIN {
    use_ok( 'Tivoli::AccessManager::Admin' );
}

ReadMode 2;
print "sec_master password: ";
my $pswd = <STDIN>;
ReadMode 0;
chomp $pswd;
print "\n";

my $pd = Tivoli::AccessManager::Admin->new( password => $pswd);
my $objspc = Tivoli::AccessManager::Admin::Objectspace->new( $pd, name => '/test/mojo', type => 11 );
my ($resp, $create);

isa_ok( $objspc, 'Tivoli::AccessManager::Admin::Objectspace' );

print "\nTESTING new and create\n";

$resp = $objspc->create(desc => 'Bad monkey', type => 11);
is($resp->isok, 1, "Created /test/mojo") or diag($resp->messages);

$resp = $objspc->delete;
is($resp->isok, 1, "Deleted /test/mojo") or diag($resp->messages);

$resp = $objspc->delete;
is($resp->isok, 0, "Couldn't delete it twice");

$objspc = Tivoli::AccessManager::Admin::Objectspace->new( $pd, 
							  name => '/test/mojo',
							  desc => 'Then I remembered he was a bad monkey',
							  type => 'container',
							 );
isa_ok( $objspc, 'Tivoli::AccessManager::Admin::Objectspace' );
$resp = $objspc->create();
is($resp->isok, 1, "Recreated /test/mojo") or diag($resp->messages);

$resp = $objspc->delete;

$objspc = Tivoli::AccessManager::Admin::Objectspace->new( $pd, 
							  desc => 'Then I remembered he was a bad monkey',
							 );
isa_ok( $objspc, 'Tivoli::AccessManager::Admin::Objectspace' );
$resp = $objspc->create(type => 11,name => '/test/mojo');
is($resp->isok, 1, "Recreated /test/mojo") or diag($resp->messages);

$resp = $objspc->list();
is($resp->isok, 1, "Listed objectspaces") or diag($resp->messages);

$resp = Tivoli::AccessManager::Admin::Objectspace->list($pd);
is($resp->isok, 1, "Listed objectspaces") or diag($resp->messages);

$resp = $objspc->delete;
$resp = Tivoli::AccessManager::Admin::Objectspace->create( $pd, 
							  name => '/test/mojo',
							  desc => 'Then I remembered he was a bad monkey',
							  type => 'container',
							 );
$objspc = $resp->value;
$resp = $objspc->create;
is($resp->iswarning,1,"Could not create it twice");


print "\nTESTING broken calls\n";
$resp = $objspc->create(qw/one two three/);
is($resp->isok,0,"Could not call create with an odd number of parameters");

my $name = $objspc->{name};
$objspc->{name} = "";

$resp = $objspc->delete;
is($resp->isok,0,"Could not delete a nameless objectspace");

$objspc->{name} = $name;

$objspc = Tivoli::AccessManager::Admin::Objectspace->new();
is($objspc, undef, "Could not call new with an empty parameter list");

$objspc = Tivoli::AccessManager::Admin::Objectspace->new( qw/one two three/ );
is($objspc, undef, "Could not call new with a non-context object");

$objspc = Tivoli::AccessManager::Admin::Objectspace->new( $pd, qw/one two three/ );
is($objspc, undef, "Could not call new with an odd number of parameters");

$objspc = Tivoli::AccessManager::Admin::Objectspace->new( $pd, 
							  name => '/test/mojo',
							  type => 19,
							 );
is($objspc, undef, "Could not call new with an invalid numeric type");

$objspc = Tivoli::AccessManager::Admin::Objectspace->new( $pd, 
							  name => '/test/mojo',
							  type => 'wiki',
							 );
is($objspc, undef, "Could not call new with an invalid named type");

$objspc = Tivoli::AccessManager::Admin::Objectspace->create();
is($objspc, undef, "Could not call create with an empty parameter list");

$resp = Tivoli::AccessManager::Admin::Objectspace->create( qw/one two three/ );
is($resp->isok, 0, "Could not call create with a non-context object");

$resp = Tivoli::AccessManager::Admin::Objectspace->create( $pd, qw/one two three/ );
is($resp->isok, 0, "Could not call create with an odd number of parameters");

$resp = Tivoli::AccessManager::Admin::Objectspace->create( $pd, 
							  name => '/test/mojo',
							  type => 19,
							 );
is($resp->isok, 0, "Could not call create with an invalid numeric type");

$resp = Tivoli::AccessManager::Admin::Objectspace->create( $pd, 
							  desc => 'Then I remembered he was a bad monkey',
							  type => 'container',
							 );
is($resp->isok, 0, "Could not call create without a name");

print "\nTESTing evil\n";

$objspc = Tivoli::AccessManager::Admin::Objectspace->new( $pd, 
							  name => '/test/mojo',
							  desc => 'Then I remembered he was a bad monkey',
							 );
$resp = $objspc->create(type => 11);
$objspc->{exist} = 0;
$resp = $objspc->create;
is($resp->isok,0,"Could not create evil");

$objspc->{exist} = 1;
$resp = $objspc->delete;
$objspc->{exist} = 1;
$resp = $objspc->delete;
is($resp->isok, 0, "Could not delete evil");


END {
    ReadMode 0;
}
