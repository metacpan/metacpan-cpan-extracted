use Test2::V0 -target => 'Webservice::Judobase';
use Data::Dumper;

subtest competitions => sub {
    my $api = $CLASS->new();

    my $result = $api->general->competitions;

    is $result->[0],
        {
        'ages'             => ['sen'],
        'city'             => E,
        'code_live_theme'  => E,
        'comp_year'        => E,
        'competition_code' => E,
        'continent_short'  => E,
        'country_short'    => E,
        'country'          => E,
        'date_from'        => E,
        'date_to'          => E,
        'has_logo'         => E,
        'has_results'      => E,
        'id_competition'   => E,
        'id_country'       => E,
        'id_live_theme'    => E,
        'is_teams'         => E,
        'name'             => E,
        'prime_event'      => E,
        'rank_name'        => E,
        'status'           => E,
        'street'           => E,
        'street_no'        => E,
        'timezone'         => E,
        'updated_at_ts'    => E,
        'updated_at'       => E,
        },
        'Returns correct data.';
};
done_testing;
