# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Opentracker-Stats.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('WWW::Opentracker::Stats::Mode::Peer') };
BEGIN { use_ok('WWW::Opentracker::Stats::UserAgent') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(
    WWW::Opentracker::Stats::Mode::Peer->_format,
    'txt'
);

is(
    WWW::Opentracker::Stats::Mode::Peer->_mode,
    'peer'
);

my $statsurl = 'http://localhost:6969/stats';

my $stats = WWW::Opentracker::Stats::Mode::Peer->new(
    {
        'statsurl'  => $statsurl,
        'useragent' => WWW::Opentracker::Stats::UserAgent->default,
    }
);

isa_ok($stats, 'WWW::Opentracker::Stats::Mode::Peer');

is(
    $stats->_statsurl,
    $statsurl
);

is(
    $stats->url,
    'http://localhost:6969/stats?format=txt&mode=peer',
);


my $payload = <<'EOF';
4
3
opentracker serving 2 torrents
opentracker
EOF

is_deeply(
    $stats->parse_stats($payload),
    {
        'peers'     => 4,
        'seeds'     => 3,
        'torrents'  => 2,
    }
);


# Thousands delimiter
$payload = <<'EOF';
1'234
987
opentracker serving 13 torrents
opentracker
EOF

is_deeply(
    $stats->parse_stats($payload),
    {
        'peers'     => 1234,
        'seeds'     => 987,
        'torrents'  => 13,
    }
);
