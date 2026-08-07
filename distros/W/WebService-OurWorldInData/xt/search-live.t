use Test2::V0;

use WebService::OurWorldInData::Search;

my $search = WebService::OurWorldInData::Search->new();

subtest 'Search object ok' => sub {
    is $search, object {
        prop isa => 'WebService::OurWorldInData::Search';

        field type     => 'charts';

        field base_url => 'https://ourworldindata.org';
        field ua       => check_isa 'HTTP::Tiny';

        end();
    }, 'Chart object correct';
};

subtest 'custom Search object' => sub {
    my $countries = join '~', qw(Canada France Chile Japan);
    my $chart = WebService::OurWorldInData::Search->new(
        countries => $countries,
        topics    => 'Health',
    );
    is $chart, object {
        prop isa => 'WebService::OurWorldInData::Search';

        field type => 'charts';
        field countries => $countries;
        field topics    => 'Health';

        field base_url => 'https://ourworldindata.org';
        field ua       => check_isa 'HTTP::Tiny';

        end();
    }, 'Search object (chart) correct';

    is $chart->require_all_countries, F(), 'requireAllCountries is false by default';
    ok $chart->require_all_countries(1), 'Can set requireAllCountries';
    is $chart->require_all_countries, T(), 'requireAllCountries is set to true';
};

subtest 'simple Chart Search' => sub {
    ok my $gdp = $search->query('gdp'), 'Search on "gdp"';

    my $results_check = hash {
            field title => E();
            field slug => E();
            field type => E(); # chart explorerView multiDimView
            field availableEntities => array { all_items match qr/^[A-Z]/; etc(); };
            field availableTabs => bag {
                all_items match qr/ LineChart
                    | Table | DiscreteBar
                    | WorldMap | SlopeChart | Marimekko
                    | ScatterPlot | StackedBar
                    | StackedArea | StackedDiscreteBar
                    /x;
            };
            field publishedAt => E();
            field updatedAt => E();
            field url => match qr!https://ourworldindata.org!;

            all_keys match qr/ title
                | slug | subtitle | variantName | type | queryParams | containerTitle
                | availableEntities | originalAvailableEntities
                | availableTabs | publishedAt | updatedAt | url
                /x;
            etc();
            # optional: containerTitle subtitle originalAvailableEntities variantName publishedAt updatedAt
        };

    is $gdp, hash {
        field query => 'gdp';
	    field results => array { all_items $results_check; etc(); };
	    field nbHits => T();
	    field page => D();
	    field nbPages => T();
	    field hitsPerPage => T();
	    field error => DNE();
    }, 'Got ChartSearchResponse for query "gdp"';

    my @urls;
    for my $chart ( $gdp->{results}->@* ) {
        like $chart->{title}, qr/gdp/i, 'Has GDP in title';
        like $chart->{url}, qr/grapher/, 'hash URL for Chart endpoint';
        push @urls, $chart->{url};
    }
    is scalar $gdp->{results}->@*, 20, 'Returned 20 results per page';

    is [$search->extract_urls($gdp)], \@urls, 'extract_urls gets a list';
};

subtest 'Page Search' => sub {
    my $pages = WebService::OurWorldInData::Search->new(
        type        => 'pages',
        page        => 1,
        hitsPerPage => 10,
    );
    is $pages, object {
        prop isa => 'WebService::OurWorldInData::Search';

        field type        => 'pages';
        field page        => 1;
        field hitsPerPage => 10;

        field base_url => 'https://ourworldindata.org';
        field ua       => check_isa 'HTTP::Tiny';

        end();
    }, 'Page Search object correct';

    my $PageResults_check = hash {
            field title => E();
            field slug => E();
            field type => 'article'; # about-page
            field thumbnailUrl => E();
            field date => E();
            field modifiedDate => E();
            field content => E();
            field authors => array { etc(); };
            field url => match $search->base_url;
            end();
        }; # optional: thumbnailUrl, date, modifiedDate, content, authors

    ok my $gdp = $pages->query('gdp'), 'Page Search on "gdp"';
    is $gdp, hash {
        field query => 'gdp';
	    field results => array { all_items $PageResults_check; etc(); };
	    field nbHits => T();
	    field offset => T();
	    field length => T();
	    field error => DNE();
    }, 'Got PageSearchResponse for query "gdp"';
};


done_testing();
