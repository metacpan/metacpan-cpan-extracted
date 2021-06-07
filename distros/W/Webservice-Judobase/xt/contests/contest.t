use Test2::V0 -target => 'Webservice::Judobase';

subtest missing_id => sub {
    my $api = $CLASS->new();

    my $result = $api->contests->contest();

    is $result,
        { error => 'id parameter is required' },
        'Returns error if no CONTEST_ID provided.';
};

subtest CHKHVIMIANI_LAI_WORLDS_2019 => sub {
    my $api = $CLASS->new();

    my $result = $api->contests->contest( id => 'wc_sen2019_m_0060_0010' );

    is $result, [
        {

            'weight' => '-60',
            'personal_picture_white' =>
                'https://www.judobase.org/files/persons//2019/02//15116_1550581155.jpg',
            'picture_filename_1' => '15116_1550581155.jpg',
            'ippon_w'            => '1',
            'id_ijf_white'       => '71454548',
            'id_weight'          => '1',
            'is_finished'        => '1',

            'is_finished'         => '1',
            'rank_name'           => 'World Championships',
            'tagged'              => '3',
            'country_short_blue'  => 'HKG',
            'waza'                => '1',
            'id_competition'      => '1751',
            'sc_countdown_offset' => '2',
            'person_white'        => 'CHKHVIMIANI Lukhumi',
            'fight_no'            => '10',
            'contest_code_long'   => 'wc_sen2019_m_0060_0010',
            'round'               => '6',
            'yuko'                => '0',
            'given_name_white'    => 'Lukhumi',
            'ippon'               => '1',
            'round_name'          => 'Round 1',
            'medias'              => [
                {   'id_fight_media'       => '63830',
                    'camera_short'         => 'front',
                    'id_camera'            => '1',
                    'thumbnail'            => undef,
                    'contest_start_offset' => '16',
                    'linked_at'            => '2019-08-25 02:30:06',
                    'published_at'         => '2019-08-25 02:28:27',
                    'url_dash'             => undef,
                    'media_ext_id'         => 'aTQ-jvodRU4',
                    'camera'               => 'Front',
                    'media_type'           => 'yt',
                    'status'               => '0',
                    'contest_code'         => 'wc_sen2019_m_0060_0010',
                    'url_m3u8'             => undef
                }
            ],
            'id_fight'               => '497339',
            'penalty_b'              => '2',
            'id_person_white'        => '15116',
            'timestamp_version_blue' => 'v1577212241',
            'country_short_white'    => 'GEO',
            'media'                  => 'yt*aTQ-jvodRU4*00:00:16',
            'id_country_blue'        => '131',
            'external_id'            => 'wc_sen2019',
            'penalty_w'              => '0',
            'id_country_white'       => '6',
            'yuko_w'                 => '0',
            'picture_folder_2'       => '/2019/12/',
            'ippon_b'                => '0',
            'scores'                 => [],
            'penalty'                => '2',
            'events'                 => [
                {   'public'   => '1',
                    'official' => '1',
                    'id_event' => '129801',
                    'duration' => '0.00',

                    'tags' => [
                        {   'name'       => 'Shido',
                            'code_short' => undef,
                            'id_group'   => '1',
                            'id_groups'  => '1',
                            'group_name' => 'Score',
                            'id_tag'     => '4',
                            'public'     => '1',
                            'id_event'   => '129801'
                        },
                        {   'name'       => 'Defensive-Posture',
                            'id_groups'  => '36,38',
                            'id_group'   => '38',
                            'code_short' => undef,
                            'id_tag'     => '313',
                            'group_name' => 'Shido',
                            'id_event'   => '129801',
                            'public'     => '1'
                        }
                    ],
                    'time_sc_gs'   => '0.00',
                    'created_at'   => '2019-08-25 02:30:57',
                    'is_gs'        => '0',
                    'id_color'     => undef,
                    'video_offset' => '-10.00',
                    'time_real'    => '38.90',
                    'actors'       => [
                        {   'id_actor'      => '136781',
                            'id_event'      => '129801',
                            'given_name'    => 'Yiu Long',
                            'actor_type'    => 'competitor',
                            'family_name'   => 'LAI',
                            'country_short' => 'HKG',
                            'id_person'     => '34360'
                        }
                    ],
                    'id_user'           => '68389',
                    'custom_title'      => undef,
                    'rating'            => 0,
                    'tags_full'         => undef,
                    'updated_at'        => '2019-08-25 02:30:57',
                    'video_offset_out'  => '5.00',
                    'id_event_group'    => '0',
                    'time_real_gs'      => '0.00',
                    'time_sc'           => '34.00',
                    'contest_code_long' => 'wc_sen2019_m_0060_0010'
                },
                {   'tags_full'         => undef,
                    'rating'            => 0,
                    'contest_code_long' => 'wc_sen2019_m_0060_0010',

                    'time_sc'          => '92.00',
                    'updated_at'       => '2019-08-25 02:30:58',
                    'video_offset_out' => '5.00',
                    'id_event_group'   => '0',
                    'time_real_gs'     => '0.00',
                    'tags'             => [
                        {   'name'       => 'Waza-ari',
                            'id_group'   => '1',
                            'id_groups'  => '1',
                            'code_short' => undef,
                            'id_tag'     => '2',
                            'group_name' => 'Score',
                            'id_event'   => '129802',
                            'public'     => '1'
                        },
                        {   'group_name' => 'Te-waza',
                            'id_tag'     => '284',
                            'id_event'   => '129802',
                            'public'     => '1',
                            'name'       => 'Tai-otoshi',
                            'id_group'   => '33',
                            'id_groups'  => '28,33',
                            'code_short' => undef
                        }
                    ],
                    'time_sc_gs'   => '0.00',
                    'created_at'   => '2019-08-25 02:30:58',
                    'public'       => '1',
                    'official'     => '1',
                    'id_event'     => '129802',
                    'duration'     => '0.00',
                    'id_user'      => '68389',
                    'custom_title' => undef,
                    'is_gs'        => '0',
                    'id_color'     => undef,
                    'video_offset' => '-5.00',
                    'time_real'    => '102.00',
                    'actors'       => [
                        {   'id_person'     => '15116',
                            'country_short' => 'GEO',
                            'actor_type'    => 'competitor',
                            'family_name'   => 'CHKHVIMIANI',
                            'given_name'    => 'Lukhumi',
                            'id_actor'      => '136782',
                            'id_event'      => '129802'
                        }
                    ]
                },
                {   'is_gs'    => '0',
                    'id_color' => undef,

                    'actors' => [
                        {   'id_actor'      => '136783',
                            'id_event'      => '129803',
                            'given_name'    => 'Yiu Long',
                            'actor_type'    => 'competitor',
                            'family_name'   => 'LAI',
                            'id_person'     => '34360',
                            'country_short' => 'HKG'
                        }
                    ],
                    'video_offset' => '-10.00',
                    'time_real'    => '173.90',
                    'id_user'      => '68389',
                    'custom_title' => undef,
                    'public'       => '1',
                    'duration'     => '0.00',
                    'id_event'     => '129803',
                    'official'     => '1',
                    'created_at'   => '2019-08-25 02:30:58',
                    'time_sc_gs'   => '0.00',
                    'tags'         => [
                        {   'id_event'   => '129803',
                            'public'     => '1',
                            'id_tag'     => '4',
                            'group_name' => 'Score',
                            'id_groups'  => '1',
                            'id_group'   => '1',
                            'code_short' => undef,
                            'name'       => 'Shido'
                        },
                        {   'id_event'   => '129803',
                            'public'     => '1',
                            'id_tag'     => '338',
                            'group_name' => 'Shido',
                            'id_group'   => '38',
                            'id_groups'  => '36,38',
                            'code_short' => undef,
                            'name'       => 'Non-Combativity'
                        }
                    ],
                    'updated_at'        => '2019-08-25 02:30:58',
                    'id_event_group'    => '0',
                    'video_offset_out'  => '7.40',
                    'time_real_gs'      => '0.00',
                    'time_sc'           => '145.00',
                    'contest_code_long' => 'wc_sen2019_m_0060_0010',
                    'rating'            => 0,
                    'tags_full'         => undef
                },
                {   'time_real_gs' => '0.00',

                    'updated_at'        => '2019-08-25 02:30:58',
                    'id_event_group'    => '0',
                    'video_offset_out'  => '5.00',
                    'time_sc'           => '220.00',
                    'contest_code_long' => 'wc_sen2019_m_0060_0010',
                    'rating'            => 0,
                    'tags_full'         => undef,
                    'actors'            => [
                        {   'id_event'      => '129804',
                            'id_actor'      => '136784',
                            'given_name'    => 'Lukhumi',
                            'family_name'   => 'CHKHVIMIANI',
                            'actor_type'    => 'competitor',
                            'id_person'     => '15116',
                            'country_short' => 'GEO'
                        }
                    ],
                    'time_real'    => '254.60',
                    'video_offset' => '-5.00',
                    'is_gs'        => '0',
                    'id_color'     => undef,
                    'custom_title' => undef,
                    'id_user'      => '68389',
                    'public'       => '1',
                    'duration'     => '0.00',
                    'id_event'     => '129804',
                    'official'     => '1',
                    'time_sc_gs'   => '0.00',
                    'created_at'   => '2019-08-25 02:30:58',
                    'tags'         => [
                        {   'code_short' => undef,
                            'id_group'   => '1',
                            'id_groups'  => '1',
                            'name'       => 'Ippon',
                            'public'     => '1',
                            'id_event'   => '129804',
                            'group_name' => 'Score',
                            'id_tag'     => '1'
                        },
                        {   'group_name' => 'Ma-sutemi-waza',
                            'id_tag'     => '268',
                            'public'     => '1',
                            'id_event'   => '129804',
                            'name'       => 'Sumi-gaeshi',
                            'code_short' => undef,
                            'id_group'   => '31',
                            'id_groups'  => '28,31'
                        }
                    ]
                }
            ],

            'person_blue'             => 'LAI Yiu Long',
            'timestamp_version_white' => 'v1608548799',
            'comp_year'               => '2019',
            'given_name_blue'         => 'Yiu Long',
            'published'               => '1',
            'picture_folder_1'        => '/2019/02/',
            'date_raw'                => '2019/08/25',
            'yuko_b'                  => '0',
            'id_ijf_blue'             => '4c5e3933',
            'id_person_blue'          => '34360',
            'gs'                      => '0',
            'country_blue'            => 'Hong Kong, China',
            'round_code'              => 'last8_rep_131_1-64',
            'duration'                => '00:03:40',
            'competition_date'        => '2019-08-25',
            'kodokan_tagged'          => '2',
            'bye'                     => '0',
            'personal_picture_blue' =>
                'https://www.judobase.org/files/persons//2019/12//34360_1577212241.jpg',
            'date_start_ts'      => '1566698879506',
            'waza_b'             => '0',
            'updated_at'         => '2020-05-04 05:57:46',
            'id_winner'          => '15116',
            'picture_filename_2' => '34360_1577212241.jpg',
            'country_white'      => 'Georgia',
            'age'                => 'Seniors',
            'waza_w'             => '1',
            'type'               => '0',
            'city'               => 'Tokyo',
            'fight_duration'     => '240',
            'first_hajime_at_ts' => '1566698881',
            'family_name_blue'   => 'LAI',
            'competition_name'   => 'World Championships Senior 2019',
            'family_name_white'  => 'CHKHVIMIANI'

        },
        ],
        'Full event data returned';

};

done_testing;
