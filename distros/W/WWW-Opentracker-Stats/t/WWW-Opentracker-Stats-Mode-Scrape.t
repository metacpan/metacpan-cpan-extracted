# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Opentracker-Stats.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('WWW::Opentracker::Stats::Mode::Scrape') };
BEGIN { use_ok('WWW::Opentracker::Stats::UserAgent') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(
    WWW::Opentracker::Stats::Mode::Scrape->_format,
    'txt'
);

is(
    WWW::Opentracker::Stats::Mode::Scrape->_mode,
    'scrp'
);

my $statsurl = 'http://localhost:6969/stats';

my $stats = WWW::Opentracker::Stats::Mode::Scrape->new(
    {
        'statsurl'  => $statsurl,
        'useragent' => WWW::Opentracker::Stats::UserAgent->default,
    }
);

isa_ok($stats, 'WWW::Opentracker::Stats::Mode::Scrape');

is(
    $stats->_statsurl,
    $statsurl
);

is(
    $stats->url,
    'http://localhost:6969/stats?format=txt&mode=scrp',
);


my $payload = <<'EOF';
19
2
33275 seconds (9 hours)
opentracker scrape stats, 1 scrape/s (tcp and udp)
EOF

is_deeply(
    $stats->parse_stats($payload),
    {
        'tcp_scrapes'       => 19,
        'udp_scrapes'       => 2,
        'uptime'            => 33275,
        'scrapes_per_sec'   => 1,
    }
);

