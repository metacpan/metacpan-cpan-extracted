#!/usr/bin/perl
# vim: set filetype=perl:
# COVER:Action.pm
use strict;
use warnings;
use Term::ReadKey;
use Data::Dumper;

use Test::More tests => 45;

BEGIN {
    use_ok( 'Tivoli::AccessManager::Admin' );
}

ReadMode 2;
print "sec_master password: ";
my $pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $pd = Tivoli::AccessManager::Admin->new( password => $pswd);
my $resp;

print "\nTESTING action creates\n";
my $act = Tivoli::AccessManager::Admin::Action->new( $pd, actionid    => 'Z',
					description => 'Test action',
				        type        => 'Test action');
isa_ok( $act, 'Tivoli::AccessManager::Admin::Action' );
$resp = $act->create;
is( $resp->isok, 1, "Vanilla create worked" ) or diag($resp->messages);

$resp = $act->delete;
is( $resp->isok, 1, "Delete worked" ) or diag($resp->messages);

$act = Tivoli::AccessManager::Admin::Action->new( $pd, actionid    => 'Z',
				     type        => 'Test action');
$resp = $act->create; 
is( $resp->isok, 0, "Couldn't create an action w/o a description" );

$resp = $act->create( description => 'Test action' );
is( $resp->isok, 1, "Create worked by sending desc to create" ) 
    or diag($resp->messages);
$resp = $act->delete;

$act = Tivoli::AccessManager::Admin::Action->new( $pd, actionid    => 'Z',
				     description => 'Test action' );
				     
$resp = $act->create; 
is( $resp->isok, 0, "Couldn't create an action w/o a type" );

$resp = $act->create( type => 'Test action' );
is( $resp->isok, 1, "Create worked by sending type to create" ) 
    or diag($resp->messages);
$resp = $act->delete;

$act = Tivoli::AccessManager::Admin::Action->new( $pd, type    => 'Action test',
				     description => 'Test action' );
				     
$resp = $act->create; 
is( $resp->isok, 0, "Couldn't create an action w/o an actionid" );

$resp = $act->create( actionid => 'Z' );
is( $resp->isok, 1, "Create worked by sending actionid to create" ) 
    or diag($resp->messages);
$resp = $act->delete;

$resp = Tivoli::AccessManager::Admin::Action->create( actionid    => 'Z',
				    description => 'Test action',
				    type        => 'Test action');
is( $resp->isok, 0, "Couldn't create w/o context" ) or diag($resp->messages);
$act = $resp->value;

$resp = Tivoli::AccessManager::Admin::Action->create( $pd,actionid    => 'Z',
					description => 'Test action',
				        type        => 'Test action');
is( $resp->isok, 1, "Create instead of new" ) or diag($resp->messages);
$act = $resp->value;
isa_ok( $act, 'Tivoli::AccessManager::Admin::Action');

$resp = Tivoli::AccessManager::Admin::Action->create( $pd,actionid    => 'Z',
					description => 'Test action',
				        type        => 'Test action');
is( $resp->isok, 0, "Couldn't create an action twice" ) or diag($resp->messages);

print "\nTESTING description, id and type\n";
is( $act->description, "Test action", "Got the description back");

is( $act->type, "Test action", "Got the type back");

is( $act->id, "Z", "Got the actionid back");

print "\nTESTING group create/delete\n";
$resp = Tivoli::AccessManager::Admin::Action->group($pd);
is( $resp->isok, 1, "Got a list of action groups" )
    or diag($resp->messages);
my @groups = $resp->value;

$resp = Tivoli::AccessManager::Admin::Action->group(create => "Test" );
is( $resp->isok, 0, "Couldn't create a group w/o a context" )
    or diag( $resp->messages );

$resp = Tivoli::AccessManager::Admin::Action->group($pd, create => "Test" );
is( $resp->isok, 1, "Created a test action group" ) 
    or diag( $resp->messages );

$resp = Tivoli::AccessManager::Admin::Action->group($pd, create => "Test" );
is( $resp->isok, 0, "Coudln't create a group twice" ) 
    or diag( $resp->messages );

push @groups, 'Test';
$resp = Tivoli::AccessManager::Admin::Action->group($pd);
is_deeply( [$resp->value], \@groups, "Test was added" ) 
    or diag( Dumper($resp), $resp->messages);

$resp = Tivoli::AccessManager::Admin::Action->group($pd, remove => "Test" );
is( $resp->isok, 1, "Deleted the test group" ) or diag( $resp->messages );
pop @groups;

$resp = Tivoli::AccessManager::Admin::Action->group($pd, remove => "Test" );
is( $resp->isok, 0, "Couldn't delete a non-existant group" ) or diag( $resp->messages );

my $newgrp = [ qw/foo bar baz/ ];
$resp = $act->group(create => $newgrp);
is($resp->isok, 1, "Added a list of new groups" ) 
    or diag( $resp->messages );

push @groups, @$newgrp;
is_deeply( [$resp->value], \@groups, "All of them got there" )
    or diag( $resp->messages );

$resp = $act->group(create => $newgrp);
is($resp->isok, 0, "Couldn't add a list of groups twice" )
    or diag( $resp->messages );

print "\nTESTING create/delete in groups\n";
$resp = Tivoli::AccessManager::Admin::Action->create( $pd, 
			       actionid => 'Z',
			       description => 'Another test action',
			       type        => 'Another test action',
			       group       => 'foo'
			   );
is( $resp->isok, 1, 'Created an action in a group' ) 
    or diag( $resp->messages );
my $act1 = $resp->value;

$resp = $act1->delete( group => qw/foo/ );
is( $resp->isok, 1, 'Deleted an action from a group' ) 
    or diag( $resp->messages );

$resp = Tivoli::AccessManager::Admin::Action->create( $pd, 
			       actionid => 'Z',
			       description => 'Another test action',
			       type        => 'Another test action',
			       group       => 'foo'
			   );
$act1 = $resp->value;


print "\nTESTING list functions\n";

$resp = Tivoli::AccessManager::Admin::Action->list;
is( $resp->isok, 0, "Couldn't list the actions w/o context" ) 
    or diag($resp->messages);

$resp = Tivoli::AccessManager::Admin::Action->list($pd);
is( $resp->isok, 1, "Listed the actions" ) 
    or diag($resp->messages);

my $count = 0;
for my $obj ( $resp->value ) {
    $count++ if UNIVERSAL::isa( $obj, 'Tivoli::AccessManager::Admin::Action' );
}
is( $count, scalar($resp->value), "All $count of them were objects" );

$resp = $act1->list( group => qw/foo/ );
is( $resp->isok, 1, "Listed the actions in a group" ) 
    or diag($resp->messages);

is( scalar($resp->value), 1, "Only found the action we put there" );

my $foo = [$resp->value]->[0];

is( $foo->description, 'Another test action', 'We got the right action' );

$resp = $act1->list( group => qw/neewonk/ );
is( $resp->isok, 0, "Couldn't list actions in a non-existant group" )
    or diag($resp->messages);

print "\nCleaning up\n";

$resp = $act1->delete;

$resp = Tivoli::AccessManager::Admin::Action->group($pd, remove => $newgrp);
is($resp->isok, 1, "Removed a list of groups" ) 
    or diag( $resp->messages );

$resp = Tivoli::AccessManager::Admin::Action->group($pd, remove => $newgrp);
is($resp->isok, 0, "Couldn't remove a list of non-existant groups" ) 
    or diag( $resp->messages );

print "\nBrokeness\n";
$act = Tivoli::AccessManager::Admin::Action->new();
is( $act, undef, "Could not send new() an empty parameter list");

$act = Tivoli::AccessManager::Admin::Action->new('foo');
is( $act, undef, "Could not send new() a non-context object");

$act = Tivoli::AccessManager::Admin::Action->new($pd, 'one');
is( $act, undef, "Could not send new() an odd number of parameters"); 

$resp = Tivoli::AccessManager::Admin::Action->group($pd, 'one');
is( $resp->isok, 0, "Could not send group() an odd number of parameters"); 

$act = Tivoli::AccessManager::Admin::Action->new( $pd, actionid    => 'Z',
				description => 'Test action',
			        type        => 'Test action');

$resp = $act->create('one');
is( $resp->isok, 0, "Could not send create() an odd number of parameters"); 

$resp = $act->delete('one');
is( $resp->isok, 0, "Could not send delete() an odd number of parameters"); 

$resp = Tivoli::AccessManager::Admin::Action->list($pd,'one');
is( $resp->isok, 0, "Could not send list() an odd number of parameters"); 

END {
    $act->delete;
    ReadMode 0;
}
