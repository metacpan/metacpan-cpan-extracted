# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Opentracker-Stats.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('WWW::Opentracker::Stats::Mode::TCP4') };
BEGIN { use_ok('WWW::Opentracker::Stats::UserAgent') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(
    WWW::Opentracker::Stats::Mode::TCP4->_format,
    'txt'
);

is(
    WWW::Opentracker::Stats::Mode::TCP4->_mode,
    'tcp4'
);

my $statsurl = 'http://localhost:6969/stats';

my $stats = WWW::Opentracker::Stats::Mode::TCP4->new(
    {
        'statsurl'  => $statsurl,
        'useragent' => WWW::Opentracker::Stats::UserAgent->default,
    }
);

isa_ok($stats, 'WWW::Opentracker::Stats::Mode::TCP4');

is(
    $stats->_statsurl,
    $statsurl
);

is(
    $stats->url,
    'http://localhost:6969/stats?format=txt&mode=tcp4',
);


my $payload = <<'EOF';
119
39
33106 seconds (9 hours)
opentracker tcp4 stats, 2 conns/s :: 1 success/s.
EOF

is_deeply(
    $stats->parse_stats($payload),
    {
        'total'         => 119,
        'announces'     => 39,
        'uptime'        => 33106,
        'total_per_sec'     => 2,
        'announces_per_sec' => 1,
    }
);

