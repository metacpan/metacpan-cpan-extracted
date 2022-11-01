use Test2::V0;

use WebService::SmartRow;

die 'You need to set SMARTROW_USERNAME' unless $ENV{SMARTROW_USERNAME};
die 'You need to set SMARTROW_PASSWORD' unless $ENV{SMARTROW_PASSWORD};

my $sr = WebService::SmartRow->new;

my $challenges = $sr->get_challenges;

is $challenges->[0],
    {
    distance => E,
    end      => E,
    id       => E,
    image    => E,
    name     => E,
    start    => E,
    },
    'Challenges from API are as expected';

done_testing;
