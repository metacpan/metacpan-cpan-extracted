use Test2::V0 -target => 'Webservice::Judobase';

subtest missing_id => sub {
    my $api = $CLASS->new();

    my $result = $api->general->competition();

    is $result,
        { error => 'id parameter is required' },
        'Returns error if no ID provided.';
};

subtest europeans_2017 => sub {
    my $api = $CLASS->new();

    my $result = $api->general->competition( id => 1455 );

    is $result,
        {
        ages  => 'Seniors',
        bgpic =>
            'https://78884ca60822a34fb0e6-082b8fd5551e97bc65e327988b444396.ssl.cf3.rackcdn.com/competition_banners/eju_sen2017.jpg',
        city          => 'Warsaw',
        country       => 'Poland',
        country_short => 'POL',
        date_from     => '2017-04-20',
        date_to       => '2017-04-23',
        id            => 1455,
        is_teams      => 0,
        label         => 'Warsaw 2017',
        module        => 'competition',
        rank_group    => 'cont_champ',
        rank_name     => 'Continental Championships',
        title         => 'European Championships Seniors 2017',
        value         => 'Warsaw 2017',
        year          => '2017',
        },
        'Returns correct data.';
};
done_testing;
