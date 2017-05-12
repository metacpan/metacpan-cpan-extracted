# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Opentracker-Stats.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('WWW::Opentracker::Stats::Mode::Renew') };
BEGIN { use_ok('WWW::Opentracker::Stats::UserAgent') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(
    WWW::Opentracker::Stats::Mode::Renew->_format,
    'txt'
);

is(
    WWW::Opentracker::Stats::Mode::Renew->_mode,
    'renew'
);

my $statsurl = 'http://localhost:6969/stats';

my $stats = WWW::Opentracker::Stats::Mode::Renew->new(
    {
        'statsurl'  => $statsurl,
        'useragent' => WWW::Opentracker::Stats::UserAgent->default,
    }
);

isa_ok($stats, 'WWW::Opentracker::Stats::Mode::Renew');

is(
    $stats->_statsurl,
    $statsurl
);

is(
    $stats->url,
    'http://localhost:6969/stats?format=txt&mode=renew',
);


my $payload = <<'EOF';
00 51
01 79
02 69
03 80
41 0
42 1
43 2
44 3
EOF

is_deeply(
    $stats->parse_stats($payload),
    {
        '00'    => '51',
        '01'    => '79',
        '02'    => '69',
        '03'    => '80',
        '41'    => '0',
        '42'    => '1',
        '43'    => '2',
        '44'    => '3',
    }
);

