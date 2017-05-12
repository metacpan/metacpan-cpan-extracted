# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Opentracker-Stats.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('WWW::Opentracker::Stats::Mode::HttpErrors') };
BEGIN { use_ok('WWW::Opentracker::Stats::UserAgent') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(
    WWW::Opentracker::Stats::Mode::HttpErrors->_format,
    'txt'
);

is(
    WWW::Opentracker::Stats::Mode::HttpErrors->_mode,
    'herr'
);

my $statsurl = 'http://localhost:6969/stats';

my $stats = WWW::Opentracker::Stats::Mode::HttpErrors->new(
    {
        'statsurl'  => $statsurl,
        'useragent' => WWW::Opentracker::Stats::UserAgent->default,
    }
);

isa_ok($stats, 'WWW::Opentracker::Stats::Mode::HttpErrors');

is(
    $stats->_statsurl,
    $statsurl
);

is(
    $stats->url,
    'http://localhost:6969/stats?format=txt&mode=herr',
);


my $payload = <<'EOF';
302 RED 1
400 ... 2
400 PAR 3
400 COM 4
403 IP  5
404 INV 6
500 SRV 46
EOF

is_deeply(
    $stats->parse_stats($payload),
    {
        '302red'    => 1,
        '400'       => 2,
        '400par'    => 3,
        '400com'    => 4,
        '403ip'     => 5,
        '404inv'    => 6,
        '500srv'    => 46,
    }
);

