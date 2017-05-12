use Test::Modern;
use t::lib::Harness qw(alg skip_unless_has_keys);

skip_unless_has_keys;

SKIP: {
    skip 'Holding off on testing Algolia Analytics for now', 1;

subtest 'Analytics API' => sub {
    my $index_names = 'charlie tango';
    my $results = alg->get_popular_searches([ split ' ', $index_names ]);
    cmp_deeply $results => {
            searchCount => 0,
            topSearches => [],
        }, "Correctly found no search results for '($index_names)'"
        or diag explain $results;

    $results = alg->get_unpopular_searches(['foo']);
    cmp_deeply $results => {
            lastSearchAt        => TD->ignore,
            searchCount         => TD->ignore,
            topSearchesNoResuls => TD->ignore,
        }, "Correctly found top searches with no results on 'foo'"
        or diag explain $results;

    $results = alg->get_popular_searches;
    ok $results->{searchCount} > 0, 'Found at least one prior search attempt';
    ok $results->{topSearches}, 'Search attempt correctly returned some hits';

    $results = alg->get_popular_searches(['foo']);
    ok $results->{searchCount} > 0, 'Found at least one prior search attempt';
    ok $results->{topSearches}, 'Search attempt correctly returned some hits';
};

}

done_testing;
