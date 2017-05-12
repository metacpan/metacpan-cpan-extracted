# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Opentracker-Stats.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('WWW::Opentracker::Stats::Mode::UDP4') };
BEGIN { use_ok('WWW::Opentracker::Stats::UserAgent') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(
    WWW::Opentracker::Stats::Mode::UDP4->_format,
    'txt'
);

is(
    WWW::Opentracker::Stats::Mode::UDP4->_mode,
    'udp4'
);

my $statsurl = 'http://localhost:6969/stats';

my $stats = WWW::Opentracker::Stats::Mode::UDP4->new(
    {
        'statsurl'  => $statsurl,
        'useragent' => WWW::Opentracker::Stats::UserAgent->default,
    }
);

isa_ok($stats, 'WWW::Opentracker::Stats::Mode::UDP4');

is(
    $stats->_statsurl,
    $statsurl
);

is(
    $stats->url,
    'http://localhost:6969/stats?format=txt&mode=udp4',
);


my $payload = <<'EOF';
321
123
32082 seconds (8 hours)
opentracker udp4 stats, 2 conns/s :: 1 success/s.
EOF

is_deeply(
    $stats->parse_stats($payload),
    {
        'total'         => 321,
        'announces'     => 123,
        'uptime'        => 32082,
        'total_per_sec'     => 2,
        'announces_per_sec' => 1,
    }
);

