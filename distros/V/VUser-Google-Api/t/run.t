#!/usr/bin/perl
use warnings;
use strict;

use Test::Most tests => 3, 'die';

use FindBin;
use lib ("$FindBin::Bin/../lib");

my $gapps_domain = $ENV{GAPPS_DOMAIN};
my $gapps_user   = $ENV{GAPPS_ADMIN};
my $gapps_passwd = $ENV{GAPPS_PASSWD};

if (not $gapps_domain
	and not $gapps_user
	    and not $gapps_passwd
	) {
    warn "GAPPS_DOMAIN, GAPPS_ADMIN or GAPPS_PASSWD not set\n";
    exit;
}

warn "$gapps_domain, $gapps_user, $gapps_passwd";

use VUser::Google::ProvisioningAPI::V2_0;

## Create google object
my $google = VUser::Google::ProvisioningAPI::V2_0->new(
    $gapps_domain, $gapps_user, $gapps_passwd
);
isa_ok($google, 'VUser::Google::ProvisioningAPI::V2_0');

$google->{debug} = 1;

## IsAuthenticated
is($google->IsAuthenticated, 1, 'Authentication succeeded');

## Create user
TODO: {
    local $TODO = "test not written";
}

## Test setting password
my $user = VUser::Google::ProvisioningAPI::V2_0::UserEntry->new();
$user->Password('Foo"bar');

my $entry = $google->UpdateUser('account10', $user);

print STDERR $google->{result}{reason} if not $entry;

isa_ok($entry, 'VUser::Google::ProvisioningAPI::V2_0::UserEntry');
