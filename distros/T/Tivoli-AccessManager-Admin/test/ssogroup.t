#!/usr/bin/perl
# vim: set filetype=perl:
# COVER:SSO/Group.pm
use strict;
use warnings;
use Term::ReadKey;
use Data::Dumper;

use Test::More tests => 55;

BEGIN {
    use_ok( 'Tivoli::AccessManager::Admin' );
    use_ok( 'Tivoli::AccessManager::Admin::SSO::Group' );
}

ReadMode 2;
print "sec_master password: ";
my $pswd = <STDIN>;
ReadMode 0;
chomp $pswd;
print "\n";

print "\nTESTING new\n";
my $pd = Tivoli::AccessManager::Admin->new( password => $pswd);
my $gso = Tivoli::AccessManager::Admin::SSO::Group->new( $pd, name => 'chimchim' );
my $resp;

# Some prelim work.  We need something to group if we want to test the groups.
my @webcreds;

for ( 0 ... 4 ) {
    my $webcred;
    $resp = Tivoli::AccessManager::Admin::SSO::Web->create($pd, name => sprintf("monkey%02d",$_));
    die $resp->messages unless $resp->isok;

    $webcred = $resp->value;
    push @webcreds, $webcred;
}
my @names = map { $_->name } @webcreds;

isa_ok($gso, "Tivoli::AccessManager::Admin::SSO::Group");
is($gso->name, 'chimchim', "Retrieved the name");

$gso = Tivoli::AccessManager::Admin::SSO::Group->new($pd,name => 'chimchim',description => 'test');
is($gso->description, 'test', "Retrieved the description") or diag(Dumper($gso,$resp));

$gso = Tivoli::AccessManager::Admin::SSO::Group->new($pd,'chimchim');
is($gso->name, 'chimchim', "Retrieved the name w/o using a hash");

print "\nTESTING create and delete\n";
$resp = $gso->create();
is($resp->isok,1,'Created a resource with name and desc embedded');

$resp = $gso->create();
is($resp->iswarning,1,'Was warned about creating an existing resource');

$resp = $gso->delete();
is($resp->isok,1, 'Deleted the resource') or diag(Dumper($resp));

$resp = $gso->delete();
is($resp->isok,0, 'Could not delete a resource that does not exist');

$gso = Tivoli::AccessManager::Admin::SSO::Group->new( $pd, name => 'chimchim' );
$resp = $gso->create;
is($resp->isok,1,'Created a resource with name only');
is($gso->name,'chimchim','Got the name back');
is($gso->description, '', 'And no description');
$resp = $gso->delete();

$gso = Tivoli::AccessManager::Admin::SSO::Group->new($pd);
$resp = $gso->create('chimchim');
is($resp->isok,1,'Created a resource with name only and no hash');
is($gso->name,'chimchim','Got the name back');
is($gso->description, '', 'And no description');
$resp = $gso->delete();

$gso = Tivoli::AccessManager::Admin::SSO::Group->new($pd);
$resp = $gso->create(name => 'chimchim', description => 'test');
is($resp->isok,1,'Created a resource with name and description');
is($gso->name,'chimchim','Got the name back');
is($gso->description, 'test', 'And the description');
$resp = $gso->delete();

$gso = Tivoli::AccessManager::Admin::SSO::Group->new($pd, 
				   name => 'chimchim', 
				   description => 'test', 
				   resources=>\@webcreds);
$resp = $gso->create();
is($resp->isok,1,'Called new() with resource objects');
$resp = $gso->resources;
is_deeply([$resp->value],\@names,"And they got added during the create");
$resp = $gso->delete();

$gso = Tivoli::AccessManager::Admin::SSO::Group->new($pd, 
				   name => 'chimchim', 
				   description => 'test', 
				   resources=>\@names);
$resp = $gso->create();
is($resp->isok,1,'Called new() with resource names');
$resp = $gso->resources;
is_deeply([$resp->value],\@names,"And they got added during the create");
$resp = $gso->delete();

$resp = Tivoli::AccessManager::Admin::SSO::Group->create($pd, name => 'chimchim');
is($resp->isok,1,'Created as a class method');
isa_ok($resp->value,'Tivoli::AccessManager::Admin::SSO::Group');
$gso = $resp->value;
is($gso->name,'chimchim','Got the name back');
$resp = $gso->delete();

$resp = Tivoli::AccessManager::Admin::SSO::Group->create($pd, name => 'chimchim', resources => \@webcreds);
is($resp->isok,1,"Added resources during the create");
$gso = $resp->value;
$resp = $gso->resources;
is_deeply( [$resp->value], \@names, "The resources were added correctly");

my $newgso = Tivoli::AccessManager::Admin::SSO::Group->new($pd, name => 'chimchim');
is($resp->isok,1,"Cloned me an object");
$resp = $newgso->resources;
is_deeply([$resp->value], \@names, "And cloned it correctly");
$newgso = undef;
$resp = $gso->delete();


$resp = Tivoli::AccessManager::Admin::SSO::Group->create($pd, name => 'chimchim', resources => "");
is($resp->isok,1,"Called create with an empty list of resources");
$gso = $resp->value;
$resp = $gso->resources;
is_deeply( [$resp->value], [], "The empty resources were added correctly");
$resp = $gso->delete();

$resp = Tivoli::AccessManager::Admin::SSO::Group->create($pd, name => 'chimchim');
$gso = $resp->value;



print "\nTESTING resource add, remove and list\n";

$resp = $gso->resources( add => \@webcreds );
is( $resp->isok, 1, "Added some resources as objects" );

$resp = $gso->resources;
is_deeply( [$resp->value], \@names, "Listed all the resource names");

my $temp = pop @names;
$resp = $gso->resources( remove => $temp );
is( $resp->isok, 1, "Removed a resource" );
is_deeply([$resp->value],\@names,"The resource really was removed");

push @names,$temp;
$resp = $gso->resources( add => $temp );
is($resp->isok, 1, "Added the resource back as a name");
is_deeply([$resp->value],\@names,"The resource really was added");


print "\nTESTING list\n";

$resp = Tivoli::AccessManager::Admin::SSO::Group->list($pd, name => 'chimchim');
is($resp->isok,1,'Called list as a class method');
is(scalar($resp->value), 'chimchim', "And found chimchim");

$resp = $gso->list;
is($resp->isok,1,'Called list as an instance method');
is(scalar($resp->value), 'chimchim', "And found chimchim");

$resp = $gso->delete;
print "\nTESTING breakage\n";

$gso = Tivoli::AccessManager::Admin::SSO::Group->new();
is($gso,undef,"Empty call to new failed");

$gso = Tivoli::AccessManager::Admin::SSO::Group->new('weee');
is($gso,undef,"Sending a non-context object to new failed");

$gso = Tivoli::AccessManager::Admin::SSO::Group->new($pd,qw/one two three/);
is($gso,undef,"Sending an odd number of parameters to new failed"); 

$gso = Tivoli::AccessManager::Admin::SSO::Group->new($pd);

$resp = Tivoli::AccessManager::Admin::SSO::Group->create('bwahaha');
is($resp->isok,0,"Bad class method call to create() failed");

$resp = $gso->create(qw/one two three/);
is($resp->isok,0,"Sending create() an odd number of parameters failed"); 

$resp = $gso->create();
is($resp->isok,0,"Could not create a nameless resource group");

$resp  = $gso->resources( qw/one two three/ );
is($resp->isok,0,"Sending resources() an odd number of parameters failed"); 

$resp = $gso->get;
is($resp->isok,0, "Couldn't get a non-existent GSO group");

$resp = Tivoli::AccessManager::Admin::SSO::Group->list;
is($resp->isok,0, "Could not call list with an empty parameter list");

$resp = Tivoli::AccessManager::Admin::SSO::Group->list(name => 'chimchim');
is($resp->isok,0, "Could not call list with a non-context object");


print "\nTESTING evil\n";

$gso->{exist} = 1;
$resp = $gso->delete;
is($gso->exist,1,"Evil could not be removed");

$resp = $gso->resources( add => \@webcreds );
is($resp->isok,0,"Could not add resources to evil");

$gso->{exist} = 0;

$gso = Tivoli::AccessManager::Admin::SSO::Group->new($pd, 
				   name => 'chimchim', 
				   description => 'test', 
				   resources=>\@names);
$resp = $gso->create();

$gso->{exist} = 0;
$resp = $gso->create;
is($resp->isok, 0, "Creating evil was denied");

$gso->{exist} = 1;
$resp = $gso->delete;

print "\nCleaning up\n";

$gso->delete if ( $gso and $gso->exist );
for my $webcred ( @webcreds ) {
    $webcred->delete;
}
