#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use VMOMI;

my ($stub, $instance, $content, $session);

$stub = new VMOMI::SoapStub(host => $ENV{VSPHERE_HOST});
$instance = new VMOMI::ServiceInstance(
    $stub, 
    new VMOMI::ManagedObjectReference(
        type  => 'ServiceInstance',
        value => 'ServiceInstance',
    ),
);

# Login
$content = $instance->RetrieveServiceContent;
isa_ok($content, "VMOMI::ServiceContent");
$session = $content->sessionManager->Login(userName => $ENV{VSPHERE_USER}, password => $ENV{VSPHERE_PASS});
isa_ok($session, "VMOMI::UserSession");

like($session->{userName}, qr/$ENV{VSPHERE_USER}/i, "session username matches environment 'VSPHERE_USER'");

# Logout
$content->sessionManager->Logout();

dies_ok(
	sub { 
		$content->sessionManager->SessionIsActive(sessionID => $session->{key}, userName => $session->{userName});
	}, 
	'session logout ok');

done_testing;