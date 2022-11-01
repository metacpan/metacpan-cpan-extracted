use Test2::V0 -target => 'Webservice::Judobase';

subtest no_params => sub {
    my $api = $CLASS->new();

    my $contests = $api->competitor->contests;

    is $contests,
        { error => 'id parameter is required' },
        'Returns error if no ID provided.';
};

subtest valid_params => sub {
    my $api = $CLASS->new();

    my $contests = $api->competitor->contests( id => 385 );

    is [ sort keys %{ $contests->{contests}[0] } ], [
        qw/
            age
            competition_date
            competition_name
            contest_code
            country_blue
            country_short_blue
            country_short_white
            country_white
            date_raw
            duration
            fight_no
            id_competition
            id_country_blue
            id_country_white
            id_fight
            id_person_blue
            id_person_white
            id_winner
            ippon
            ippon_b
            ippon_w
            penalty
            penalty_b
            penalty_w
            person_blue
            person_blue_family_name
            person_blue_given_name
            person_white
            person_white_family_name
            person_white_given_name
            personal_picture_blue
            personal_picture_white
            picture_filename_1
            picture_filename_2
            picture_folder_1
            picture_folder_2
            round
            round_name
            type
            waza
            waza_b
            waza_w
            weight
            yuko
            yuko_b
            yuko_w

            /
        ],
        'Returns data structure for valid competitor';
};

subtest invalid_params => sub {
    my $api = $CLASS->new();

    my $contests = $api->competitor->contests( id => 0 );

    is $contests,
        { error => 'player_vs_player.error.id_person_not_given', },
        'Returns error for invalid or not found competitor';
};

done_testing;
