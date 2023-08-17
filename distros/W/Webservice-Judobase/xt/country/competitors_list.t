use Test2::V0 -target => 'Webservice::Judobase';

my $api = $CLASS->new();

subtest missing_id => sub {
    my $result = $api->country->competitors_list();

    is $result,
        { error => 'id_country parameter is required' },
        'Returns error if no COUNTRY_ID provided.';
};

subtest bad_id => sub {
    my $result = $api->country->competitors_list( id_country => "MLT" );

    is $result,
        { error => 'id_country parameter must be an integer' },
        'Returns error if no COUNTRY_ID provided is not an integer.';
};

subtest good_list => sub {
    my $result = $api->country->competitors_list( id_country => 138 );

    is scalar keys %$result, 2, 'Number of athletes listed should be 2';

    is $result->{9730},
        {
        categories       => E,
        family_name      => 'BEZZINA',
        folder           => E,
        given_name       => 'Isaac',
        id_person        => 9730,
        id_weight        => E,
        name             => E,
        order_cat_number => E,
        personal_picture => E,
        picture_filename => E,
        place            => E,
        sum_points       => E,
        weight_name      => E,
        wrl              => E,
        },
        'Isaac Bezzina';
};

done_testing;
