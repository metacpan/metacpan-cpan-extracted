#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use IO::Scalar;
use lib 'lib';
use ThreatDetector::Reporter qw(generate_summary);

my @events = (
    { ip => '192.168.1.1', uri => '/login' },
    { ip => '192.168.1.2', uri => '/login' },
    { ip => '192.168.1.1', uri => '/admin' },
    { ip => '192.168.1.3', uri => '/login' },
    { ip => '192.168.1.2', uri => '/admin' },
    { ip => '192.168.1.2', uri => '/admin' },
);

my $output = '';
open my $fh, '>', \$output or die "Can't open in-memory filehandle: $!";

generate_summary('Test Threat', \@events, $fh);
close $fh;

like($output, qr/=== Test Threat Summary ===/, 'Contains label header');
like($output, qr/Total:\s+6/, 'Correct total count');
like($output, qr/Unique IPs:/, 'has Unique IPs section');
like($output, qr/Targeted URIs:/, 'Has Targeted URIs section');

like($output, qr/192\.168\.1\.1 \(2 hits\)/, 'Correct count for 192.168.1.1');
like($output, qr/192\.168\.1\.2 \(3 hits\)/, 'Correct count for 192.168.1.2');
like($output, qr/192\.168\.1\.3 \(1 hits\)/, 'Correct count for 192.168.1.3');

like($output, qr/\/login \(3 times\)/, 'Correct count for /login');
like($output, qr/\/admin \(3 times\)/, 'Correct count for /admin');

done_testing();