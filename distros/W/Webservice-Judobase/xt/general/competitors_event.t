use Test2::V0 -target => 'Webservice::Judobase';

subtest missing_id => sub {
    my $api = $CLASS->new();

    my $result = $api->general->competitors();

    is $result,
        { error => 'event_id parameter is required' },
        'Returns error if no Event_ID provided.';
};

subtest europeans_2017 => sub {
    my $api = $CLASS->new();

    my $result = $api->general->competitors( event_id => 1455 );

    is $result,
        array {
        {   birth_date           => E,
            category             => E,
            club_name            => E,
            club_name_official   => E,
            contests_lost        => E,
            contests_won         => E,
            country              => E,
            country_short        => E,
            date_from            => E,
            family_name          => E,
            folder               => E,
            gender               => E,
            given_name           => E,
            id_age               => E,
            id_club              => E,
            id_country           => E,
            id_ijf               => E,
            id_person            => E,
            id_weight            => E,
            name                 => E,
            personal_picture     => E,
            picture_filename     => E,
            place                => E,
            ranking_place        => E,
            seed_group           => E,
            show_seed            => E,
            ts_person_updated_at => E,
            wra_place            => E,
            wra_points           => E,
        },
            etc(),
        },
        'Returns correct data.';
};

done_testing;
