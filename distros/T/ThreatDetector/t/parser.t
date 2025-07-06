use strict;
use warnings;
use Test::More tests => 6;

use lib 'lib';
use ThreatDetector::Parser;

$ThreatDetector::Parser::STATS{parsed} = 0;
$ThreatDetector::Parser::STATS{skipped} = 0;

my $valid_line = q{
192.168.1.100 - - [20/Jun/2025:14:23:56 -0700] "GET /test.php?id=5%20AND%201=1 HTTP/1.1" 200 512 "-" "Mozilla/5.0"
};
$valid_line =~ s/^\s+//;


my $entry = ThreatDetector::Parser::parse_log_line($valid_line);

ok(defined $entry, 'Valid log line parsed successfully');
is($entry->{ip}, '192.168.1.100', 'IP address parsed');
is($entry->{uri}, '/test.php?id=5 AND 1=1', 'URI decoded correctly');
is($entry->{status}, '200', 'Status code parsed correctly');

my $invalid_line = q{
invalid-log-line-without-proper-format
};

my $entry2 = ThreatDetector::Parser::parse_log_line($invalid_line);
ok(!defined $entry2, 'Invalid log line skipped');

is_deeply(
    \%ThreatDetector::Parser::STATS,
    { parsed => 1, skipped => 1 },
    'Stats updated correctly'
);