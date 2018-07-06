use Test2::V0 -target => 'Webservice::Judobase';

subtest no_params => sub {
    my $api = $CLASS->new();

    my $result = $api->competitor->fights_statistics;

    is $result,
      { error => 'id parameter is required' },
      'Returns error if no ID provided.';
};

subtest valid_params => sub {
    my $api = $CLASS->new();

    # https://judobase.ijf.org/#/competitor/profile/7350/statistics
    my $result = $api->competitor->fights_statistics( id => 7350 );

    is $result,
      {
        longest_winning_fights   => E,
        total_duration_sec       => E,
        shortest_fight_win_date  => E,
        longest_fight_win_date   => E,
        num_win_by_ippon         => E,
        longest_fight_win_comp   => E,
        num_contests_by_ippon    => E,
        avg_duration             => E,
        shortest_fight_win_comp  => E,
        shortest_fight_win_with  => E,
        shortest_fight_win_sec   => undef,
        longest_fight_win        => E,
        shortest_fight_lost_with => E,
        shortest_fight_lost_sec  => E,
        shortest_fight_lost_date => E,
        shortest_fight_lost_comp => E,
        shortest_fight_lost      => E,
        longest_fight_lost_with  => E,
        longest_fight_lost_sec   => E,
        longest_fight_lost_date  => E,
        longest_fight_lost_comp  => E,
        longest_fight_lost       => E,
        num_lost_by_ippon_proc   => E,
        num_lost_by_ippon        => E,
        unbeaten_statistics      => {
            beaten_by           => E,
            competition_name    => E,
            competition_date    => E,
            days                => E,
            since               => E,
            id_person_beaten_by => E,
        },
        shortest_fight_win     => E,
        longest_fight_win_with => E,
        total_duration         => E,
        avg_duration_sec       => E,
        num_lost               => E,
        num_contests           => E,
        longest_fight_win_sec  => undef,
        num_win_by_ippon_proc  => E,
        current_winning_period => E,
        num_win                => E,
      },
      'Returns data structure for valid competitor';
};

subtest invalid_params => sub {
    my $api = $CLASS->new();

    my $result = $api->competitor->fights_statistics( id => 0 );

    is $result,
      { error => 'statistics.error.id_person_not_given', },
      'Returns error for invalid or not found competitor';
};

done_testing;
