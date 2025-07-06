#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use lib 'lib';

use ThreatDetector::Classifier;

my @tests = (
    {
        name => 'Detects SQL Injection (UNION SELECT)',
        entry => {
            ip => '1.2.3.4',
            method => 'GET',
            uri => '/index.php?id=1 UNION SELECT password FROM users',
            status => 200,
            user_agent => 'TestAgent',
        },
        expected => ['sql_injection'],
    },
    {
        name => 'Detects XSS (<script>)',
        entry => {
            ip => '1.2.3.5',
            method => 'GET',
            uri => '/search?q=<script>alert(1)</script>',
            status => 200,
            user_agent => 'TestAgent',
        },
        expected => ['xss_attempt'],
    },
    {
        name => 'Detects no threat (harmless request)',
        entry => {
            ip => '1.2.3.6',
            method => 'GET',
            uri => '/about.html',
            status => 200,
            user_agent => 'Mozilla',
        },
        expected => [],
    },
);

plan tests => scalar @tests;

for my $test (@tests) {
    my @detected = ThreatDetector::Classifier::classify($test->{entry});
    is_deeply(
        \@detected,
        $test->{expected},
        $test->{name}
    );
}