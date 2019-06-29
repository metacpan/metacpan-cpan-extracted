use Test::More;
use Test::MockDateTime;

use Data::Dumper;

BEGIN {
    use_ok( 'WWW::AzimuthAero::Utils', qw(:all) );
}

subtest 'get_next_dow_date' => sub {
    plan tests => 3;
    is get_next_dow_date( '9.06.2019',  7 )->dmy('.'), '09.06.2019';
    is get_next_dow_date( '07.06.2019', 7 )->dmy('.'), '09.06.2019';
    is get_next_dow_date( '07.06.2019', 3 )->dmy('.'), '12.06.2019';
};

subtest 'get_next_dow_date_dmy' => sub {
    plan tests => 3;
    is get_next_dow_date_dmy( '9.06.2019',  7 ), '09.06.2019';
    is get_next_dow_date_dmy( '07.06.2019', 7 ), '09.06.2019';
    is get_next_dow_date_dmy( '07.06.2019', 3 ), '12.06.2019';
};

subtest 'get_dates_from_dows' => sub {

    # Check when today < min < max
    on '2019-01-01 00:00:01' => sub {
        is_deeply(
            [
                get_dates_from_dows(
                    min  => '2019-06-10',
                    max  => '2019-06-16',
                    days => '25'
                )
            ],
            [ '11.06.2019', '14.06.2019' ],
            'one week'
        );

        is_deeply(
            [
                get_dates_from_dows(
                    min  => '2019-06-10',
                    max  => '2019-06-23',
                    days => '25'
                )
            ],
            [ '11.06.2019', '14.06.2019', '18.06.2019', '21.06.2019' ],
            'two weeks'
        );

        is_deeply(
            [
                get_dates_from_dows(
                    min  => '2019-06-24',
                    max  => '2019-07-07',
                    days => '25'
                )
            ],
            [ '25.06.2019', '28.06.2019', '02.07.2019', '05.07.2019' ],
            'dates range are in diff month'
        );

        is_deeply(
            [
                get_dates_from_dows(
                    min  => '2019-12-23',
                    max  => '2020-01-05',
                    days => '25'
                )
            ],
            [ '24.12.2019', '27.12.2019', '31.12.2019', '03.01.2020' ],
            'dates range are in diff year'
        );
    };

    # Check when min < today < max
    on '2019-12-30 00:00:01' => sub {
        is_deeply(
            [
                get_dates_from_dows(
                    min  => '2019-12-23',
                    max  => '2020-01-05',
                    days => '25'
                )
            ],
            [ '31.12.2019', '03.01.2020' ],
            'dates range are in diff year when min < today < max'
        );
    };

    on '2019-05-01 03:04:05' => sub {
        is_deeply(
            [
                get_dates_from_dows(
                    max  => '2019-04-27',
                    days => '25'
                )
            ],
            [],
'return an empty array if min_date is not specified and max date < today'
        );
    };

};

subtest 'filter_dates' => sub {

    is_deeply(
        [
            filter_dates(
                [qw/03.06.2019 07.06.2019 11.06.2019 15.06.2019/],
                max => '12.06.2019',
                min => '07.06.2019'
            )
        ],
        [qw/07.06.2019 11.06.2019/],
        'dates filtering is ok'
    );

};

subtest 'get_dates_from_range' => sub {

    is_deeply(
        [ get_dates_from_range( min => '10.06.2019', max => '12.06.2019' ) ],
        [qw/10.06.2019 11.06.2019 12.06.2019/],
        'ok with min and max'
    );

    on '2019-06-10 03:04:05' => sub {
        is_deeply(
            [ get_dates_from_range( max => '12.06.2019' ) ],
            [qw/10.06.2019 11.06.2019 12.06.2019/],
            'ok with with mocked DateTime and max only'
        );
    };
};

subtest 'pairwise' => sub {

    is_deeply(
        [
            iata_pairwise(
                [ [ 'ROV', 'MOW', 'LED' ], [ 'ROV', 'KRR', 'LED' ] ]
            )
        ],
        [
            { from => 'ROV', via => 'MOW', to => 'LED' },
            { from => 'ROV', via => 'KRR', to => 'LED' }
        ]
    );

};

done_testing();
