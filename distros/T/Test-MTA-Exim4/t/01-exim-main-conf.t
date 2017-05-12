#!/usr/bin/perl

use FindBin qw($Bin);
use Test::More 'no_plan';

BEGIN {
    use_ok('Test::MTA::Exim4');
}

my $exim_path = "$Bin/scripts/fake_exim";

my $exim = Test::MTA::Exim4->new( { exim_path => $exim_path, debug => 1 } );
ok( $exim, 'Created exim test object' );
$exim->config_ok;

# check the version numbers
ok( ( $exim->exim_version eq '4.74' ), 'Check version number' );
ok( ( $exim->exim_version > 4.60 ),    'Check version better than 4.60' );

# build number - no idea why you want this!
ok( ( $exim->exim_build == 1 ), 'Check build number' );

# check that binary has lsearch cdb ldap pgsql lookups
foreach (qw[lsearch cdb ldap mysql]) {
    $exim->has_capability( 'lookup', $_ );
}

# but do not want the exploding lookup!
$exim->has_not_capability( 'lookup', 'exploding' );

# routing - we want accept dnslookup manualroute redirect
foreach (qw[dnslookup manualroute redirect]) {
    $exim->has_capability( 'router', $_ );
}

# transports - we want appendfile maildir autoreply pipe smtp
foreach (qw[appendfile maildir autoreply pipe smtp]) {
    $exim->has_capability( 'transport', $_ );
}

# other stuff - we need DKIM openssl content_scanning
foreach (qw[dkim openssl content_scanning]) {
    $exim->has_capability( 'support_for', $_ );
}

# but do not want the root hole
$exim->has_not_capability( 'support_for', 'go_on_hack_me' );
