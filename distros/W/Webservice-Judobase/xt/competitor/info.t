use Test2::V0 -target => 'Webservice::Judobase';

subtest info_no_params => sub {
    my $api = $CLASS->new();

    my $info = $api->competitor->info;

    is $info,
        { error => 'id parameter is required' },
        'Returns error if no ID provided.';
};

subtest info_valid_params => sub {
    my $api = $CLASS->new();

    my $info = $api->competitor->info( id => 1 );

## Please see file perltidy.ERR
    is $info,
        {
        age               => E,
        archived          => 0,
        belt              => undef,
        best_result       => undef,
        birth_date        => E,
        categories        => [''],
        club              => undef,
        death_age         => undef,
        dob_year          => 1960,
        coach             => '',
        country_short     => 'SLO',
        country           => 'Slovenia',
        family_name_local => 'BULC',
        family_name       => 'BULC',
        file_flag         => 'Slovenia.gif',
        folder            => '/2017/02/',
        ftechique         => '',
        gender            => 'male',
        given_name_local  => "Ale\x{161}",
        given_name        => 'Ales',
        height            => 0,
        id_country        => 1,
        middle_name_local => '',
        middle_name       => '',
        name              => '1_1488190109.jpg',
        personal_picture  =>
            'https://www.judobase.org/files/persons//2017/02//1_1488190109.jpg',
        picture_filename => '1_1488190109.jpg',
        short_name       => '',
        side             => 0,
        status           => 1,
        youtube_links    => undef,
        },
        'Returns data structure for valid competitor';
};

subtest info_not_valid_params => sub {
    my $api = $CLASS->new();

    my $info = $api->competitor->info( id => 0 );

    is $info,
        { error => 'info.error.id_person_not_given', },
        'Returns error for invalid or not found competitor';
};

=pod
# Stubs here as paceholders for the methods from PHP app.
use Test2::Todo;

my $todo = Test2::Todo->new(reason => 'Not yet implemented');
    subtest best_results => sub {};
    subtest best_results_2 => sub {};
    subtest best_results_wrl => sub {};
    subtest birthday_competitors => sub {};
    subtest contests => sub {};
    subtest contests_statistics => sub {};
    subtest find_id => sub {};
    subtest get_biography => sub {};
    subtest get_files => sub {};
    subtest get_images => sub {};
    subtest get_links_by_category => sub {};
    subtest get_list => sub {};
    subtest get_ogq_qual => sub {};
    subtest info => sub {};
    subtest last_category => sub {};
    subtest medals => sub {};
    subtest ogq => sub {};
    subtest ogq_competitions => sub {};
    subtest place_by_rank => sub {};
    subtest player_vs_player => sub {};
    subtest results => sub {};
    subtest results2 => sub {};
    subtest round_info => sub {};
    subtest throw_statistics => sub {};
    subtest total_awards => sub {};
    subtest wins_losses => sub {};
    subtest wrl => sub {};
    subtest wrl_competitions => sub {};
    subtest wrl_current => sub {};
    subtest wrl_history => sub {};
$todo->end;
=cut

done_testing;
