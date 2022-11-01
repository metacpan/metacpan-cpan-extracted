use Test2::V0 -target => 'Webservice::Judobase';

subtest no_params => sub {
    my $api = $CLASS->new();

    my $result = $api->competitor->wrl_current;

    is $result,
        { error => 'id parameter is required' },
        'Returns error if no ID provided.';
};

subtest valid_params => sub {
    my $api = $CLASS->new();

    # https://judobase.ijf.org/#/competitor/profile/7350/wrl
    my $result = $api->competitor->wrl_current( id => 7350 );

    is $result,
        {
        points         => E,
        place          => E,
        id_weight      => E,
        age            => E,
        weight         => E,
        ogq_place      => E,
        ogq_sum_points => E,
        q_status       => E,
        },
        'Returns data structure for valid competitor';
};

subtest invalid_params => sub {
    my $api = $CLASS->new();

    my $result = $api->competitor->wrl_current( id => 0 );

    is $result,
        { error => 'wrl.error.id_person_not_given', },
        'Returns error for invalid or not found competitor';
};

done_testing;
