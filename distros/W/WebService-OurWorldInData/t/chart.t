use Test2::V0;

BEGIN {
    $ENV{ LWP_UA_MOCK } ||= 'playback';
    $ENV{ LWP_UA_MOCK_FILE } ||= __FILE__.'-lwp-mock.out';
}

use WebService::OurWorldInData::Chart;

use Test2::Require::Module 'LWP::UserAgent';
use Test2::Require::Module 'LWP::UserAgent::Mockable';
use Test2::Require::Module 'URI';
use Time::Piece; # core module

my $time = localtime;
my $record_date = $ENV{ LWP_UA_MOCK } eq 'playback'
    ? '2026-08-06'
    : $time->ymd;
diag 'Remember to set $record_date = ', $time->ymd, " in $0"
    if $ENV{ LWP_UA_MOCK } eq 'record';

my $dataset = 'sea-surface-temperature-anomaly';
my $ua    = LWP::UserAgent->new;
$ua->agent('WebService::OurWorldInData-test/0.1');
my $chart = WebService::OurWorldInData::Chart->new( chart => $dataset, ua => $ua );

subtest 'Chart object ok' => sub {
    is $chart, object {
        prop isa => 'WebService::OurWorldInData::Chart';

        field chart       => $dataset;
        field csv_type    => 'full';
        field short_names => F();

        field base_url => 'https://ourworldindata.org';
        field ua       => check_isa 'LWP::UserAgent';

        end();
    }, 'Chart object correct';
};

subtest 'filtered data' => sub {
    my ($result, );
    my $gdp   = WebService::OurWorldInData::Chart->new(
                    chart    => 'gdp-per-capita-worldbank',
                    csv_type => 'filtered',
                    time     => 2020,
                    ua       => $ua );
    my $japan = WebService::OurWorldInData::Chart->new(
                    chart    => 'life-expectancy',
                    csv_type => 'filtered',
                    country  => 'Japan',
                    ua       => $ua ); # ~JPN
    my $chile = WebService::OurWorldInData::Chart->new(
                    chart    => 'life-expectancy',
                    csv_type => 'filtered',
                    country  => '~CHL',
                    time     => '1998..2023',
                    ua       => $ua );

    ok $result = $gdp->data(), 'fetch GDP for 2020';
    ok $result = $japan->data(), 'fetch life expectancy for Japan';
    ok $result = $chile->data(), 'fetch life expectancy for the last 25 years in Chile';
};

subtest 'fetch using short column names' => sub {
    $chart->short_names( 1 ); # set to true
    ok my $result = $chart->data, 'Get data (short_names true)';
};

subtest 'fetch metadata' => sub {
    ok my $result = $chart->metadata, 'Get metadata';
    # $result is JSON and need to use hash builder

    my $chart_check = hash {
            field title => match qr/^Annual sea surface temperature/;
            field subtitle => E();
            field citation => match qr/^Met Office Hadley Centre/;
            field originalChartUrl => $chart->get_path;
            field selection => ['World'];
            field note => E();
            end();
        };
    my $date_check = qr/^\d{4}-[01]\d-[0-3]\d$/;
    my $column_check = hash {
            field citationShort => E();
            field citationLong => E();
            field descriptionKey => match qr/\w/;
            field descriptionShort => E();
            field descriptionProcessing => E();
            field fullMetadata
                => match qr(^https://api.ourworldindata.org/v1/indicators/\d+.metadata.json);
            field lastUpdated => match $date_check;
            field nextUpdate => match $date_check;
            field owidVariableId => match qr/^\d+$/;
            field shortName => match qr/^sea_temperature/;
            field shortUnit => E();
            field timespan => match qr/^1850-20\d{2}/;
            field titleLong => E();
            field titleShort => E();
            field type => 'Numeric';
            field unit => 'degrees Celsius';

            end();
    };

    is $result,
        hash {
            field chart => $chart_check;
            field columns => E();
            field dateDownloaded => $record_date;

            end();
        },
        'check JSON fields';

    # loop through very long key names because nested hashes are hard to test
    # could this be done as a bag { } check?
    for my $key (sort keys %{$result->{columns}} ) {
        is $result->{columns}->{$key}, $column_check, "check column metadata for $key";
    }
};

subtest 'fetch readme' => sub {
    ok my $result = $chart->readme, 'Get readme';

    like $result, qr/^# Annual sea surface temperature/,
        'check README.md title';
    like $result, qr/^## CSV Structure/m,
        'check README.md heading';
};

subtest 'fetch config' => sub {
    ok my $result = $chart->config, 'Get config';

    is $result,
        hash {
            field id => E();
            field note => E();

            etc();
        },
        'check JSON fields';
};

subtest 'fetch values' => sub {
    ok my $result = $chart->values, 'Get values';

    is $result,
        hash {
            field entityName => E();
            field columns => E();
            field startTime => E();
            field endTime => E();
            field source => E();
            field startValues => E();
            field endValues => E();

            end();
        },
        'check JSON fields';
};

subtest 'fetch search_result' => sub {
    ok my $result = $chart->search_result, 'Get search_result';

    is $result,
        hash {
            field dataTable => E();
            field entityType => E();
            field entityTypePlural => E();
            field grapherQueryParams => E();
            field layout => E();
            field numAvailableEntities => E();
            field source => E();
            field subtitle => E();
            field title => E();
            field unit => E();

            end();
        },
        'check JSON fields';
};

done_testing();

END {
    # END block ensures cleanup if script dies early
    LWP::UserAgent::Mockable->finished;
}
