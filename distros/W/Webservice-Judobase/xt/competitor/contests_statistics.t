use Test2::V0 -target => 'Webservice::Judobase';

subtest no_params => sub {
    my $api = $CLASS->new();

    my $stats = $api->competitor->contests_statistics;

    is $stats,
        { error => 'id parameter is required' },
        'Returns error if no ID provided.';
};

subtest valid_params => sub {
    my $api = $CLASS->new();

    my $stats = $api->competitor->contests_statistics( id => 385 );

    is [ sort keys %$stats ], [
        qw/
            avg_duration
            avg_duration_sec
            current_winning_period
            longest_fight_lost
            longest_fight_lost_comp
            longest_fight_lost_date
            longest_fight_lost_sec
            longest_fight_lost_with
            longest_fight_win
            longest_fight_win_comp
            longest_fight_win_date
            longest_fight_win_sec
            longest_fight_win_with
            longest_winning_fights
            num_contests
            num_contests_by_ippon
            num_lost
            num_lost_by_ippon
            num_lost_by_ippon_proc
            num_win
            num_win_by_ippon
            num_win_by_ippon_proc
            shortest_fight_lost
            shortest_fight_lost_comp
            shortest_fight_lost_date
            shortest_fight_lost_sec
            shortest_fight_lost_with
            shortest_fight_win
            shortest_fight_win_comp
            shortest_fight_win_date
            shortest_fight_win_sec
            shortest_fight_win_with
            total_duration
            total_duration_sec
            unbeaten_statistics
            /
        ],
        'Returns data structure for valid competitor';
};

subtest invalid_params => sub {
    my $api = $CLASS->new();

    my $stats = $api->competitor->contests_statistics( id => 0 );

    is $stats,
        { error => 'statistics.error.id_person_not_given', },
        'Returns error for invalid or not found competitor';
};

done_testing;
