use Test2::V0;

BEGIN {
    $ENV{ LWP_UA_MOCK } ||= 'playback';
    $ENV{ LWP_UA_MOCK_FILE } ||= __FILE__.'-lwp-mock.out';
}

use WebService::OurWorldInData::Chart;

use Archive::Extract;
use LWP::UserAgent::Mockable;
use Time::Piece; # core module

my $time = localtime;
my $record_date = $ENV{ LWP_UA_MOCK } eq 'playback'
    ? '2025-07-16'
    : $time->ymd;

my $dataset = 'sea-surface-temperature-anomaly';
my $chart = WebService::OurWorldInData::Chart->new( chart => $dataset );

subtest 'Chart object ok' => sub {
    is $chart, object {
        prop isa => 'WebService::OurWorldInData::Chart';

        field chart       => $dataset;
        field csv_type    => 'full';
        field short_names => F();

        field base_url => 'https://ourworldindata.org';
        field ua       => check_isa 'HTTP::Tiny';

        end();
    }, 'Chart object correct';
};

subtest data => sub {
    my $body = get_data_subset();

    my $data = $chart->parse_data( $body );
    is ref $data, 'ARRAY';
        
    ok my $result = $chart->data(), "Fetch chart data for $dataset";
    like $result, qr/^Entity,Code,Year,Annual sea surface temperature/, 'returns CSV data';
};

subtest 'filtered data' => sub {
    my ($result, );
    my $gdp   = WebService::OurWorldInData::Chart->new(
                    chart => 'gdp-per-capita-worldbank',
                    csv_type => 'filtered',
                    time => 2020 );
    my $japan = WebService::OurWorldInData::Chart->new(
                    chart => 'life-expectancy',
                    csv_type => 'filtered',
                    country => 'Japan' ); # ~JPN
    my $chile = WebService::OurWorldInData::Chart->new(
                    chart => 'life-expectancy',
                    csv_type => 'filtered',
                    country => '~CHL',
                    time => '1998..2023' );

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
            field descriptionKey => array { all_items match qr/\w/; etc(); };
            field descriptionShort => E();
            field fullMetadata
                => match qr(^https://api.ourworldindata.org/v1/indicators/\d+.metadata.json);
            field lastUpdated => match $date_check;
            field nextUpdate => match $date_check;
            field owidVariableId => match qr/^\d+$/;
            field shortName => match qr/^sea_temperature/;
            field shortUnit => E();
            field timespan => "1850-2025";
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
    for my $key (sort keys %{$result->{columns}} ) {
        is $result->{columns}->{$key}, $column_check, "check column metadata for $key";
    }
};

subtest 'zipped package' => sub {
    ok my $result = $chart->zip, 'Get zipped package';

    my $filename = join '.', $dataset, 'zip';
    open my $fh, '>:raw', $filename
        or warn "Can't open $filename: $!\n", return;
    print $fh $result; # write the binary file
    close $fh;

    my $ae = Archive::Extract->new( archive => $filename );
    ok $ae->extract or diag $ae->error;
    my $files = $ae->files;
    is $files, [ "$dataset.metadata.json", "$dataset.csv", 'readme.md'], 'Files there';

    unlink $filename, @$files;
};

done_testing();

END {
    # END block ensures cleanup if script dies early
    LWP::UserAgent::Mockable->finished;
}

sub get_data_subset {
    return <<DATA;
Entity,Code,Year,Annual sea surface temperature anomalies,Annual sea surface temperature anomalies (lower bound),Annual sea surface temperature anomalies (upper bound)
Northern Hemisphere,,1850,-0.053766724,-0.12948489,-0.0016253028
Northern Hemisphere,,1851,0.06586428,-0.008639886,0.11984695
Northern Hemisphere,,1852,0.14944454,0.079167694,0.20091112
Northern Hemisphere,,1853,0.11939995,0.054722864,0.17239437
DATA
}
