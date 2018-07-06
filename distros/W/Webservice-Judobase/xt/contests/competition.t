use Test2::V0 -target => 'Webservice::Judobase';

subtest missing_id => sub {
    my $api = $CLASS->new();

    my $result = $api->contests->competition();

    is $result,
      { error => 'id parameter is required' },
      'Returns error if no COMPETITION_ID provided.';
};

subtest europeans_2017 => sub {
    my $api = $CLASS->new();

    my $result = $api->contests->competition( id => 1455 );

## Please see file perltidy.ERR
    is $result->[0],
      {
        age                 => 'Seniors',
        bye                 => 0,
        city                => 'Warsaw',
        comp_year           => 2017,
        competition_date    => '2017-04-20',
        competition_name    => 'European Championships Seniors 2017',
        contest_code_long   => 'eju_sen2017_w_0078_0001',
        country_blue        => 'Russia',
        country_short_blue  => 'RUS',
        country_short_white => 'NED',
        country_white       => 'Netherlands',
        date_raw            => '2017/04/20',
        date_start_ts       => 1492855745049,
        duration            => '00:01:54',
        external_id         => 'eju_sen2017',
        family_name_blue    => 'SHMELEVA',
        family_name_white   => 'STEENHUIS',
        fight_no            => 1,
        given_name_blue     => 'Antonina',
        given_name_white    => 'Guusje',
        gs                  => 0,
        id_competition      => 1455,
        id_country_blue     => 7,
        id_country_white    => 28,
        id_fight            => 330429,
        id_ijf_blue         => '74ac3d1d',
        id_ijf_white        => '3d2f4f17',
        id_person_blue      => 14919,
        id_person_white     => 3389,
        id_weight           => 13,
        id_winner           => 3389,
        ippon_b             => 0,
        ippon_w             => 1,
        ippon               => 1,
        media               => undef,
        penalty_b           => 0,
        penalty_w           => 0,
        penalty             => 0,
        person_blue         => 'SHMELEVA Antonina',
        person_white        => 'STEENHUIS Guusje',
        personal_picture_blue =>
          'https://www.judobase.org/files/persons//2013/10//28728_28727_.jpg',
        personal_picture_white =>
'https://www.judobase.org/files/persons//imported//4757_1026600001006.jpg',
        picture_filename_1  => '4757_1026600001006.jpg',
        picture_filename_2  => '28728_28727_.jpg',
        picture_folder_1    => '/imported/',
        picture_folder_2    => '/2013/10/',
        rank_name           => 'European Championships',
        round_code          => 'last8_rep_19_1-8',
        round_name          => 'Round 1',
        round               => 3,
        sc_countdown_offset => 0,
        tagged              => 0,
        type                => 0,
        updated_at          => '2017-04-22 10:13:18',
        waza_b              => 0,
        waza_w              => 2,
        waza                => 2,
        weight              => '-78',
        yuko_b              => 0,
        yuko_w              => 0,
        yuko                => 0,
      },
      'Returns correct data.';
};

done_testing;
