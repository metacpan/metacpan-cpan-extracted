# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Opentracker-Stats.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('WWW::Opentracker::Stats') };
BEGIN { use_ok('LWP::UserAgent') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $baseurl     = 'http://localhost:6969/stats';
my $useragent   = LWP::UserAgent->new();

$useragent->timeout(2);
$useragent->agent('Dummy Agent/1.0 ');

my $stats = WWW::Opentracker::Stats->new(
    {
        'statsurl'  => $baseurl,
        'useragent' => $useragent,
    }
);

isa_ok($stats, 'WWW::Opentracker::Stats');

my $mode = $stats->get_mode('tpbs');
isa_ok(
    $mode,
    WWW::Opentracker::Stats::Mode::TPBS
);

# Requires a running server
#$tpbs = $stats->stats_tpbs;
#
#isa_ok(
#    $tpbs,
#    HASH
#);


