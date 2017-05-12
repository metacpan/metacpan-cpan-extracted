#!/usr/bin/perl
# vim: set filetype=perl:
# COVER:SSO/Web.pm
use strict;
use warnings;
use Term::ReadKey;
use Data::Dumper;

use Test::More tests => 41;

BEGIN {
    use_ok( 'Tivoli::AccessManager::Admin' );
    use_ok( 'Tivoli::AccessManager::Admin::SSO::Web' );
}

ReadMode 2;
print "sec_master password: ";
my $pswd = <STDIN>;
ReadMode 0;
chomp $pswd;
print "\n";

print "\nTESTING new\n";
my $pd = Tivoli::AccessManager::Admin->new( password => $pswd);
my $sso = Tivoli::AccessManager::Admin::SSO::Web->new( $pd, name => 'twiki' );
my $resp;

isa_ok($sso, "Tivoli::AccessManager::Admin::SSO::Web");
is($sso->name, 'twiki', "Retrieved the name");

$sso = Tivoli::AccessManager::Admin::SSO::Web->new($pd,name => 'twiki',desc => 'test');
isa_ok($sso, "Tivoli::AccessManager::Admin::SSO::Web");
is($sso->name, 'twiki', "Retrieved the name");
is($sso->description, 'test', "Retrieved the description");

$sso = Tivoli::AccessManager::Admin::SSO::Web->new($pd,'twiki');
isa_ok($sso, "Tivoli::AccessManager::Admin::SSO::Web");
is($sso->name, 'twiki', "Retrieved the name w/o using a hash");

print "\nTESTING create and delete\n";
$resp = $sso->create();
is($resp->isok,1,'Created a resource with name and desc embedded');

$resp = $sso->create();
is($resp->iswarning,1,'Was warned about creating an existing resource');

$resp = $sso->delete();
is($resp->isok,1, 'Deleted the resource') or diag(Dumper($resp));

$resp = $sso->delete();
is($resp->isok,0, 'Could not delete a resource that does not exist');

$sso = Tivoli::AccessManager::Admin::SSO::Web->new($pd,name =>
    'twiki',desc=>'Foo' );
$resp = $sso->create;
is($resp->isok,1,'Created a resource with name only');
is($sso->name,'twiki','Got the name back');
is($sso->description, 'Foo', 'And no description');
$resp = $sso->delete();

$sso = Tivoli::AccessManager::Admin::SSO::Web->new($pd);
$resp = $sso->create('twiki');
is($resp->isok,1,'Created a resource with name only and no hash');
is($sso->name,'twiki','Got the name back');
is($sso->description, '', 'And no description');
$resp = $sso->delete();

$sso = Tivoli::AccessManager::Admin::SSO::Web->new($pd);
$resp = $sso->create(name => 'twiki', desc => 'test');
is($resp->isok,1,'Created a resource with name and description');
is($sso->name,'twiki','Got the name back');
is($sso->description, 'test', 'And the description');
$resp = $sso->delete();

$resp = Tivoli::AccessManager::Admin::SSO::Web->create($pd, name => 'twiki');
is($resp->isok,1,'Finally, created as a class method');
isa_ok($resp->value,'Tivoli::AccessManager::Admin::SSO::Web');
$sso = $resp->value;
is($sso->name,'twiki','Got the name back');
$resp = $sso->delete;

print "\nTESTING list\n";

$resp = Tivoli::AccessManager::Admin::SSO::Web->create($pd, name => 'twiki');
$sso = $resp->value;

$resp = Tivoli::AccessManager::Admin::SSO::Web->list($pd, name => 'twiki');
is($resp->isok,1,'Called list as a class method');
is(scalar($resp->value), 'twiki', "And found twiki");

$resp = $sso->list;
is($resp->isok,1,'Called list as an instance method');
is(scalar($resp->value), 'twiki', "And found twiki");

$resp = $sso->delete;
print "\nTESTING breakage\n";

$sso = Tivoli::AccessManager::Admin::SSO::Web->new();
is($sso,undef,"Couldn't create a resource w/o a context");
$sso = Tivoli::AccessManager::Admin::SSO::Web->new('wiki');
is($sso,undef,"Couldn't create a resource with something that isn't a context");
$sso = Tivoli::AccessManager::Admin::SSO::Web->new($pd, qw/one two three/);
is($sso,undef,"Couldn't send an odd number of parameters");

$resp = Tivoli::AccessManager::Admin::SSO::Web->create();
is($resp->isok,0,"create() fails when new() fails");
$resp = Tivoli::AccessManager::Admin::SSO::Web->create($pd, qw/one two three/);
is($resp->isok,0,"Couldn't send an odd number of parameters");
$resp = Tivoli::AccessManager::Admin::SSO::Web->create($pd);
is($resp->isok,0,"Couldn't create an unnamed resource");

$resp = Tivoli::AccessManager::Admin::SSO::Web->list();
is($resp->isok,0,"Could not call list without an empty list");
$resp = Tivoli::AccessManager::Admin::SSO::Web->list(qw/one two three/);
is($resp->isok,0,"Could not call list with a non-context");

$sso = Tivoli::AccessManager::Admin::SSO::Web->new($pd);
$resp = $sso->create(qw/one two three/);
is($resp->isok,0,"Couldn't send an odd number of parameters");

my $name = $sso->name;
is($name,'', 'Got no name from an nonexistant resource');

print "\nTESTING evil\n";
$sso->{exist} = 1;
$resp = $sso->delete;
is($resp->isok,0,"Could not delete evil");

$sso->{exist} = 0;
$resp = Tivoli::AccessManager::Admin::SSO::Web->create($pd, name => 'twiki');
$sso = $resp->value;

$sso->{exist} = 0;
$resp = $sso->create;
is($resp->isok,0,"Could not create evil");
$sso->{exist} = 1;
$resp = $sso->delete;
