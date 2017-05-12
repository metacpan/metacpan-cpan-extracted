# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Opentracker-Stats.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('WWW::Opentracker::Stats::Mode::Fullscrape') };
BEGIN { use_ok('WWW::Opentracker::Stats::UserAgent') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(
    WWW::Opentracker::Stats::Mode::Fullscrape->_format,
    'txt'
);

is(
    WWW::Opentracker::Stats::Mode::Fullscrape->_mode,
    'fscr'
);

my $statsurl = 'http://localhost:6969/stats';

my $stats = WWW::Opentracker::Stats::Mode::Fullscrape->new(
    {
        'statsurl'  => $statsurl,
        'useragent' => WWW::Opentracker::Stats::UserAgent->default,
    }
);

isa_ok($stats, 'WWW::Opentracker::Stats::Mode::Fullscrape');

is(
    $stats->_statsurl,
    $statsurl
);

is(
    $stats->url,
    'http://localhost:6969/stats?format=txt&mode=fscr',
);


my $payload = <<'EOF';
21000
1701
36369 seconds (10 hours)
opentracker full scrape stats, 1 conns/s :: 2 bytes/s.
EOF

is_deeply(
    $stats->parse_stats($payload),
    {
        'count'         => 21000,
        'size'          => 1701,
        'uptime'        => 36369,
        'count_per_sec' => 1,
        'size_per_sec'  => 2,
    }
);

