# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Opentracker-Stats.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('WWW::Opentracker::Stats::Mode::Top10') };
BEGIN { use_ok('WWW::Opentracker::Stats::UserAgent') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(
    WWW::Opentracker::Stats::Mode::Top10->_format,
    'txt'
);

is(
    WWW::Opentracker::Stats::Mode::Top10->_mode,
    'top10'
);

my $statsurl = 'http://localhost:6969/stats';

my $stats = WWW::Opentracker::Stats::Mode::Top10->new(
    {
        'statsurl'  => $statsurl,
        'useragent' => WWW::Opentracker::Stats::UserAgent->default,
    }
);

isa_ok($stats, 'WWW::Opentracker::Stats::Mode::Top10');

is(
    $stats->_statsurl,
    $statsurl
);

is(
    $stats->url,
    'http://localhost:6969/stats?format=txt&mode=top10',
);


my $payload = <<'EOF';
Top 10 torrents by peers:
        44      8C18F57626C3D514E5CFD9B991EF0D723059D0E0
        9       C407ECB3D0ACF0D0E01488960005B844BFCF2F03
Top 10 torrents by seeds:
        44      8C18F57626C3D514E5CFD9B991EF0D723059D0E0
        36      644AA544E92C6C4F498437FCD0A08D8401F55A55
        10      BEE8EDA4916BCD7A7ABB6AACADC4EA18F4855B3D
EOF

is_deeply(
    $stats->parse_stats($payload),
    {
        'peers'     => [
            {
                'count'     => 44,
                'torrent'   => '8C18F57626C3D514E5CFD9B991EF0D723059D0E0',
            },
            {
                'count'     => 9,
                'torrent'   => 'C407ECB3D0ACF0D0E01488960005B844BFCF2F03',
            },
        ],
        'seeds'     => [
            {
                'count'     => 44,
                'torrent'   => '8C18F57626C3D514E5CFD9B991EF0D723059D0E0',
            },
            {
                'count'     => 36,
                'torrent'   => '644AA544E92C6C4F498437FCD0A08D8401F55A55',
            },
            {
                'count'     => 10,
                'torrent'   => 'BEE8EDA4916BCD7A7ABB6AACADC4EA18F4855B3D',
            },
        ],
    }
);

