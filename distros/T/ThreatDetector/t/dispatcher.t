#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use lib 'lib';

use ThreatDetector::Dispatcher;
use ThreatDetector::Handlers::SQLInjection qw(get_sqli_events);
use ThreatDetector::Handlers::XSS qw(get_xss_events);

# Clear handler state
@ThreatDetector::Handlers::SQLInjection::SQLI_EVENTS = ();
@ThreatDetector::Handlers::XSS::XSS_EVENTS = ();

my $entry1 = {
    ip         => '1.2.3.4',
    method     => 'GET',
    uri        => '/index.php?id=1 UNION SELECT password FROM users',
    status     => 200,
    user_agent => 'TestAgent',
};

my $entry2 = {
    ip         => '1.2.3.5',
    method     => 'GET',
    uri        => '/search?q=<script>alert(1)</script>',
    status     => 200,
    user_agent => 'TestAgent',
};

# Run dispatcher
ThreatDetector::Dispatcher::dispatch($entry1, 'sql_injection');
ThreatDetector::Dispatcher::dispatch($entry2, 'xss_attempt');

# Check that handler arrays received alerts
my @sql_alerts = get_sqli_events();
my @xss_alerts = get_xss_events();

ok(scalar @sql_alerts == 1, 'sql_injection handler called and recorded alert');
ok(scalar @xss_alerts == 1, 'xss_attempt handler called and recorded alert');

done_testing();
