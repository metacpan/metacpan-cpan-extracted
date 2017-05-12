# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Opentracker-Stats.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('WWW::Opentracker::Stats::Mode::Conn') };
BEGIN { use_ok('WWW::Opentracker::Stats::UserAgent') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(
    WWW::Opentracker::Stats::Mode::Conn->_format,
    'txt'
);

is(
    WWW::Opentracker::Stats::Mode::Conn->_mode,
    'conn'
);

my $statsurl = 'http://localhost:6969/stats';

my $stats = WWW::Opentracker::Stats::Mode::Conn->new(
    {
        'statsurl'  => $statsurl,
        'useragent' => WWW::Opentracker::Stats::UserAgent->default,
    }
);

isa_ok($stats, 'WWW::Opentracker::Stats::Mode::Conn');

is(
    $stats->_statsurl,
    $statsurl
);

is(
    $stats->url,
    'http://localhost:6969/stats?format=txt&mode=conn',
);


my $payload = <<'EOF';
107
36
30353 seconds (8 hours)
opentracker connections, 0 conns/s :: 0 success/s.
EOF

is_deeply(
    $stats->parse_stats($payload),
    {
        'total'         => 107,
        'announces'     => 36,
        'uptime'        => 30353,
        'total_per_sec'     => 0,
        'announces_per_sec' => 0,
    }
);

