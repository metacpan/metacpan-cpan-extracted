#!/usr/bin/perl
use strict;
use warnings;
use Term::ReadKey;
use TAMeb::Admin;
use Devel::Peek;

my ( $resp, $rc, @actions, $pswd );

ReadMode 2;
print "sec_master password: ";
$pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $pd  = TAMeb::Admin::Context->new(password => $pswd );
my $acl = TAMeb::Admin->new('acl', $pd, name => 'bob');

@actions = qw/traverse read execute/;

$resp = $acl->list();
$resp->iserror() and die $resp->messages();

print "Currently defined acls: \n";
print "\t$_\n" for ( @{$resp->value()} );

# Create a new ACL
if ( $acl->exist() ) {
    print "Deleting bob\n";
    $acl->delete();
}

print "Creating ACL bob\n";
$resp  = $acl->create();
if ( $resp->iserror() ) {
    print "Error: \n";
    die join( "\n", $resp->messages());
}

print "Assigning permissions for group 'ralph'\n";
# Give the group 'ralph' permissions in this ACL
$resp = $acl->group( group => 'ralph', perms => \@actions );
if ( $resp->iserror ) {
    die $resp->messages(), "\n";
}

print "Displaying permissions\n";
# Check the group's permissions to make sure it really worked.
$resp = $acl->group( group => 'ralph' );
print "The group 'ralph' is granted these privileges by acl 'bob':\n";
for ( @{$resp->value()} ) {
    print "\t$_\n";
}

# Give the user "user01" the same access privs
$resp = $acl->user( user => 'user01', perms => 'Trx' );
if ( $resp->iserror ) {
    die $resp->messages(), "\n";
}

# Check user01's permissions to make sure it really worked.
$resp = $acl->user( user => 'user01' );
print "The user 'user01' is granted these privileges by acl 'bob':\n";
print "\t$_\n" for ( @{$resp->value()} );

print "Removing anyother\n";
# Deny all access to anyother and unauth
$resp = $acl->anyother(  perms => 'remove' );
if ( $resp->iserror() ) {
    die $resp->messages(), "\n";
}

# Verify we did what we thought
print "Getting anyother\n";
$resp = $acl->anyother();
print "any-other is granted these privileges by acl 'bob':\n";
print "\t$_\n" for ( @{$resp->value()} );

$resp = $acl->unauth( remove => 1 );
if ( $resp->iserror() ) {
    die $resp->messages(), "\n";
}

print "unauth is granted these privileges by acl 'bob':\n";
$resp = $acl->unauth( );
print "\t$_\n" for ( @{$resp->value()} );

# Finally, list the users specified in the ACL
$resp = $acl->listusers();
if ( $resp->iserror() ) {
    die $resp->messages(), "\n";
}

print "Users assigned to the acl:\n";
print "\t$_\n" for ( @{$resp->value()} );

# list the groups specified in the ACL
$resp = $acl->listgroups();
if ( $resp->iserror() ) {
    die $resp->messages(), "\n";
}
print "Groups assigned to the acl:\n";
print "\t$_\n" for ( @{$resp->value()} );

# well, that was fun.  What's say we clean up?
$resp = $acl->delete();
if ( $resp->iserror() ) {
    warn "Couldn't delete bob\n";
    die $resp->messages, "\n";
}

END {
    ReadMode 0;
}
