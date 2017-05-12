#!/usr/bin/env perl

use strict;
use warnings;

use VMOMI;
use Getopt::Long;

my ($host, $user, $pass, $stub, $instance, $content, $session, @vms);

$user = undef;
$pass = undef;
$host = 'localhost';

GetOptions(
	"user=s" => \$user,
	"pass=s" => \$pass,
	"host=s" => \$host,
);

die "Must specify user and pass parameters" if not (defined $user and defined $pass);

$stub = new VMOMI::SoapStub(host => $host) || die "Failed to initialize SoapStub";
$instance = new VMOMI::ServiceInstance(
    $stub, 
    new VMOMI::ManagedObjectReference(
        type  => 'ServiceInstance',
        value => 'ServiceInstance',
    ),
);

# Login
$content = $instance->RetrieveServiceContent;
$session = $content->sessionManager->Login(userName => $user, password => $pass);


@vms = VMOMI::find_entities($content, 'VirtualMachine');
foreach (@vms) {
    print $_->name . ", " . $_->config->guestFullName . "\n";
}

# Logout
$content->sessionManager->Logout();