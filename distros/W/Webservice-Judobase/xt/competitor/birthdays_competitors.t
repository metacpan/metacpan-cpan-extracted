use Test2::V0 -target => 'Webservice::Judobase';

subtest no_params => sub {
    my $api = $CLASS->new();

    my $result = $api->competitor->birthdays_competitors;

    is $result,
      { error => 'min_age parameter is required' },
      'Returns error if no ID provided.';
};

subtest valid_params => sub {
    my $api = $CLASS->new();

    my $result = $api->competitor->birthdays_competitors( min_age => 5 );

    is [ sort keys %{ $result->{feed}[0] } ],
      [
        'age',              'birth_date',
        'country',          'country_short',
        'family_name',      'given_name',
        'id_country',       'id_person',
        'pic_folder',       'pic_name',
        'picture_filename', 'ppic',
      ],
      'Returns data structure for valid competitor';
};

done_testing;
