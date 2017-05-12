use strict;
use warnings;
use Test::More;
use WebService::Klout;

unless ($ENV{'KLOUT_API_KEY'}) {
    Test::More->import('skip_all' => 'no api key set, skipped.');
    exit;
}

my $klout = WebService::Klout->new;

my @users = qw(twitter twitpic);

my $score = $klout->score(@users);

isa_ok($score, 'ARRAY', 'users');

is(scalar @$score, scalar @users, 'number of users');

isa_ok($score->[0], 'HASH', 'row');

is_deeply(
    [ sort keys %{ $score->[0] } ],
    [ sort qw(twitter_screen_name kscore) ],
    'api data'
);

done_testing;
