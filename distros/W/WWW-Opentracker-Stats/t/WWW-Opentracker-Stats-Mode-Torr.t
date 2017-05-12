# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Opentracker-Stats.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('WWW::Opentracker::Stats::Mode::Torr') };
BEGIN { use_ok('WWW::Opentracker::Stats::UserAgent') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(
    WWW::Opentracker::Stats::Mode::Torr->_format,
    'txt'
);

is(
    WWW::Opentracker::Stats::Mode::Torr->_mode,
    'torr'
);

my $statsurl = 'http://localhost:6969/stats';

my $stats = WWW::Opentracker::Stats::Mode::Torr->new(
    {
        'statsurl'  => $statsurl,
        'useragent' => WWW::Opentracker::Stats::UserAgent->default,
    }
);

isa_ok($stats, 'WWW::Opentracker::Stats::Mode::Torr');

is(
    $stats->_statsurl,
    $statsurl
);

is(
    $stats->url,
    'http://localhost:6969/stats?format=txt&mode=torr',
);


my $payload = <<'EOF';
2
0
opentracker serving 2 torrents
opentracker
EOF

is_deeply(
    $stats->parse_stats($payload),
    {
        'torrents'  => 2,
    }
);


# Thousands delimiter
$payload = <<'EOF';
13
0
opentracker serving 13 torrents
opentracker';
EOF

is_deeply(
    $stats->parse_stats($payload),
    {
        'torrents'  => 13,
    }
);
