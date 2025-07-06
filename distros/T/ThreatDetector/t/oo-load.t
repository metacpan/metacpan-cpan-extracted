#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

my @modules = (
    'ThreatDetector::Parser',
    'ThreatDetector::Classifier',
    'ThreatDetector::Dispatcher',
    'ThreatDetector::Reporter',

    'ThreatDetector::Handlers::SQLInjection',
    'ThreatDetector::Handlers::XSS',
    'ThreatDetector::Handlers::ClientError',
    'ThreatDetector::Handlers::CommandInjection',
    'ThreatDetector::Handlers::DirectoryTraversal',
    'ThreatDetector::Handlers::EncodedPayload',
    'ThreatDetector::Handlers::BotFingerprint',
    'ThreatDetector::Handlers::MethodAbuse',
    'ThreatDetector::Handlers::HeaderAbuse',
    'ThreatDetector::Handlers::LoginBruteForce',
    'ThreatDetector::Handlers::RateLimiter',
);

plan tests => scalar @modules;

for my $mod (@modules) {
    use_ok($mod);
}