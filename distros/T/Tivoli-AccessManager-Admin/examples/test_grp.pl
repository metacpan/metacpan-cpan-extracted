#!/usr/bin/perl
use strict;
use warnings;
use Term::ReadKey;
use TAMeb::Admin;

my ( $resp, $rc, @groups );

ReadMode 2;
print "sec_master password: ";
$pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

print "Initializing TAM context\n";
my $pd  = TAMeb::Admin::Context->new(password => $pswd );

print "Initializing group\n";
my $group = TAMeb::Admin::Group->new( $pd, name => 'ralph' );

print "Checking for ralph\n";

if ( $group->exist() ) {
    print $group->{name}, " already exists\n";
}
else {
    print $group->{name}, " doesn't exist -- attempting to create\n";
    $resp = $group->create(dn => 'cn=ralph,ou=groups,o=rox,c=us' );
    print $group->{name}, " returned from create()\n";
    if ( $resp->isok() ) {
	print $group->{name}, " successfully created\n";
    }
    else {
	print $resp->messages(), "\n";
	exit 1;
    }
}

print "Adding members to ", $group->{name}, "\n";
$resp = $group->members( add => [qw/user01 user02 user03 user04 user05/ ], force => 1 );
if ( $resp->isok ) {
    print "Added members\n";
}
elsif ( $resp->iswarning ) {
    print "Warning: " . $resp->messages() . "\n";
}
else {
    print join( "\n", $resp->messages() ), "\n";
    exit 1;
}

print "Showing members\n";
$resp = $group->members();
if ( $resp->isok ) {
    print $group->{name}, " has the following members: \n";
    print "\t$_\n" for ( @{$resp->value()} );
}

print "Removing members\n";
$resp = $group->members( remove => [qw/user02 user03/] );
if ( $resp->isok() ) {
    print "Removed members\n";
    print $group->{name}, " has the following members: \n";
    print "\t$_\n" for ( @{$resp->value()} );
}
else {
    print $resp->messages(), "\n";
    exit 1;
}

print "Adding members that are already there\n";
$resp = $group->members( add => [qw/user01 user04/ ] );
if ( $resp->isok ) {
    print "That was unexpected\n";
}
else {
    print $resp->messages, "\n";
}

print "Adding members that dont' exist\n";
$resp = $group->members( add => [qw/wqeqwe asdasd/ ] );
if ( $resp->isok ) {
    print "That was unexpected\n";
}
else {
    print $resp->messages, "\n";
}

print "Removing members that aren't in the group\n";
$resp = $group->members( remove => [qw/vaby vmone/]);
if ( $resp->isok ) {
    print "That was unexpected\n";
}
else {
    print $resp->messages, "\n";
}

print "Adding and removing users\n";
$resp = $group->members( remove => [qw/user01 user04/],
                         add    => [qw/user02 user03/ ]
			);
if ( $resp->isok ) {
    print "\t$_\n" for ( @{$resp->value()} );
}
else {
    print $resp->messages, "\n";
}

print "Listing groups\n";
$resp = $group->list( pattern => "*");
if ( $resp->isok ) {
    print "\t$_\n" for ( @{$resp->value()} );
}
else {
    print $resp->messages, "\n";
}

END {
    ReadMode 0;
}
