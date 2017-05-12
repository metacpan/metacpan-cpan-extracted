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

my $users = $klout->users_topics(@users);

isa_ok($users, 'ARRAY', 'users');

is(scalar @$users, scalar @users, 'number of users');

isa_ok($users->[0], 'HASH', 'row');

is_deeply(
    [ sort keys %{ $users->[0] } ],
    [ sort qw(twitter_screen_name topics) ],
    'api data'
);

done_testing;
