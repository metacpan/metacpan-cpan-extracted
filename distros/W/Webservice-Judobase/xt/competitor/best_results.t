use Test2::V0 -target => 'Webservice::Judobase';

subtest no_params => sub {
    my $api = $CLASS->new();

    my $result = $api->competitor->best_results;

    is $result,
      { error => 'id parameter is required' },
      'Returns error if no ID provided.';
};

subtest valid_params => sub {
    my $api = $CLASS->new();

    my $result = $api->competitor->best_results( id => 385 );

    is $result,
      [
        {
            competition => 'Grand Slam Paris 2013',
            name_short  => 'GS Paris 2013',
            place       => 1,
            points      => 500,
            rank_short  => undef,
            sort_by     => '10-1',
            year        => 2013,
        },
        {
            competition => 'Olympic Games London 2012',
            name_short  => 'OG London 2012',
            place       => 1,
            points      => 600,
            rank_short  => undef,
            sort_by     => '10-1',
            year        => 2012,
        },
        {
            competition => 'World Cup Lisbon 2012',
            name_short  => 'WCUP men Lisbon',
            place       => 1,
            points      => 100,
            rank_short  => undef,
            sort_by     => '10-1',
            year        => 2012,
        },
        {
            competition => 'Grand Slam Paris 2012',
            name_short  => 'GS Paris',
            place       => 1,
            points      => 300,
            rank_short  => undef,
            sort_by     => '10-1',
            year        => 2012,
        },
        {
            competition => 'World Championships Paris 2011',
            rank_short  => undef,
            place       => 1,
            year        => 2011,
            name_short  => 'WC Paris 2011',
            sort_by     => '10-1',
            points      => 500
        }
      ],
      'Returns data structure for valid competitor';
};

subtest invalid_params => sub {
    my $api = $CLASS->new();

    my $result = $api->competitor->best_results( id => 0 );

    is $result,
      { error => 'info.error.id_person_not_given', },
      'Returns error for invalid or not found competitor';
};

done_testing;
