use Test2::V0;

use WebService::SmartRow;

die 'You need to set SMARTROW_USERNAME' unless $ENV{SMARTROW_USERNAME};
die 'You need to set SMARTROW_PASSWORD' unless $ENV{SMARTROW_PASSWORD};

my $sr = WebService::SmartRow->new;

my $leaderboard = $sr->get_leaderboard;

is $leaderboard, {
    distribution => {
        ageMode => E,
        data    => array {
            etc(),
        },
        max            => E,
        mean           => E,
        min            => E,
        range          => E,
        userPercentile => E,
    },
    id      => E,
    mod     => E,
    records => array {
        etc(),
    },
    },
    '2000M leaderboard is default';

is $leaderboard->{distribution}{data}[0],
    {
    x => E,
    y => E,
    },
    'First distribution data item';

is $leaderboard->{records}[0],
    {
    act_position => E,
    age_class    => E,
    country      => E,
    created      => E,
    distance     => 2000,
    full_name    => E,
    gender       => E,
    id           => E,
    mod          => E,
    position     => E,
    time         => E,
    user_id      => E,
    weight_class => E,
    },
    'First row in records correct';

subtest 'distance => 5000' => sub {
    $leaderboard = $sr->get_leaderboard( distance => 5000, );
    is $leaderboard->{records}[0]{distance}, 5000, '5000M data returned';
};

subtest 'year => 2022' => sub {
    $leaderboard = $sr->get_leaderboard( year => 2022, );
    is $leaderboard->{records}[0]{distance}, 2000,
        'distance - 2000M data returned (default to 2000m if no distance param provided)';
    like $leaderboard->{records}[0]{created}, qr/^2022/,
        'created - Year 2022 data returned';
    like $leaderboard->{records}[0]{mod}, qr/^2022/,
        'mod - Year 2022 data returned';
};

subtest 'country => 188 (UK)' => sub {
    $leaderboard = $sr->get_leaderboard( country => 189 );
    like $leaderboard->{records}[0]{country}, 189, 'country - 189 returned';
};

subtest 'age => "c" (43-49)' => sub {
    $leaderboard = $sr->get_leaderboard( age => 'c' );
    like $leaderboard->{records}[0]{age_class}, 'C (43-49)',
        'age_class - C returned';
};

subtest 'gender => "f" (female)' => sub {
    $leaderboard = $sr->get_leaderboard( gender => 'f' );
    like $leaderboard->{records}[0]{gender}, 'Female',
        'gender - Female returned';
};

subtest 'weight => "l" (light)' => sub {
    $leaderboard = $sr->get_leaderboard( weight => 'l' );
    like $leaderboard->{records}[0]{weight_class}, 'LW',
        'weight_class - Lightweight returned returned';
};
done_testing;
