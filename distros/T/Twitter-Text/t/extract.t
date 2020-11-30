use Test2::V0;
use Test2::Plugin::NoWarnings;
BEGIN {
    eval {
        require Test2::Plugin::GitHub::Actions::AnnotateFailedTest;
        Test2::Plugin::GitHub::Actions::AnnotateFailedTest->import;
    };
}

use Twitter::Text::Util;
use Twitter::Text;

my $yaml = load_yaml("extract.yml");

subtest extract_hashtags => sub {
    my $testcases = $yaml->[0]->{tests}->{hashtags};

    for my $testcase (@$testcases) {
        my $parse_result = extract_hashtags($testcase->{text});
        is(
            $parse_result,
            $testcase->{expected},
            $testcase->{description},
        );
    }
};

subtest extract_hashtags_from_astral => sub {
    my $testcases = $yaml->[0]->{tests}->{hashtags_from_astral};

    for my $testcase (@$testcases) {
        my $parse_result = extract_hashtags($testcase->{text});
        is(
            $parse_result,
            $testcase->{expected},
            $testcase->{description},
        );
    }
};

subtest extract_hashtags_with_indices => sub {
    my $testcases = $yaml->[0]->{tests}->{hashtags_with_indices};

    for my $testcase (@$testcases) {
        my $parse_result = extract_hashtags_with_indices($testcase->{text});
        is(
            $parse_result,
            $testcase->{expected},
            $testcase->{description},
        );
    }

    is(
        extract_hashtags_with_indices(''),
        [],
        'No hashtags from empty string',
    );

    is(
        extract_hashtags_with_indices('https://example.com/#hoge', { check_url_overlap => 0 }),
        [
            {
                hashtag => 'hoge',
                indices => [ 20, 25 ],
            }
        ],
        "Don't check URL overlap",
    );
};

subtest extract_mentions => sub {
    my $testcases = $yaml->[0]->{tests}->{mentions};

    for my $testcase (@$testcases) {
        my $parse_result = extract_mentioned_screen_names($testcase->{text});
        is(
            $parse_result,
            $testcase->{expected},
            $testcase->{description},
        );
    }
};

subtest extract_mentions_with_indices => sub {
    my $testcases = $yaml->[0]->{tests}->{mentions_with_indices};

    for my $testcase (@$testcases) {
        my $parse_result = extract_mentioned_screen_names_with_indices($testcase->{text});
        is(
            $parse_result,
            $testcase->{expected},
            $testcase->{description},
        );
    }

    is(
        extract_mentioned_screen_names_with_indices(''),
        [],
        'No screen names from empty string',
    );

    is(
        extract_mentioned_screen_names_with_indices('@username/list'),
        [],
        'No screen names from @username/list',
    );
};

subtest extract_mentions_or_lists_with_indices => sub {
    my $testcases = $yaml->[0]->{tests}->{mentions_or_lists_with_indices};

    for my $testcase (@$testcases) {
        my $parse_result = extract_mentions_or_lists_with_indices($testcase->{text});
        is(
            $parse_result,
            $testcase->{expected},
            $testcase->{description},
        );
    }

    is(
        extract_mentions_or_lists_with_indices(''),
        [],
        'No mentions or lists from empty string',
    );
};

subtest extract_urls => sub {
    my $testcases = $yaml->[0]->{tests}->{urls};

    for my $testcase (@$testcases) {
        my $parse_result = extract_urls($testcase->{text});
        my $expected     = $testcase->{expected};
        is(
            $parse_result,
            $expected,
            $testcase->{description},
        );
    }
};

subtest extract_urls_with_indices => sub {
    my $testcases = $yaml->[0]->{tests}->{urls_with_indices};

    for my $testcase (@$testcases) {
        my $parse_result = extract_urls_with_indices($testcase->{text});
        is $parse_result, [
            map {
                {
                    url     => $_->{url},
                    indices => $_->{indices},
                }
            } @{ $testcase->{expected} }
            ],
            $testcase->{description};
    }

    is(
        extract_urls_with_indices(''),
        [],
        'No URLs from empty string',
    );

    is(
        extract_urls_with_indices('example.com', { without_protocol => 0 }),
        [],
        'force with protocol',
    );
};

subtest extract_urls_with_directional_markers => sub {
    my $testcases = $yaml->[0]->{tests}->{urls_with_directional_markers};

    for my $testcase (@$testcases) {
        my $parse_result = extract_urls_with_indices($testcase->{text});
        is $parse_result, [
            map {
                {
                    url     => $_->{url},
                    indices => $_->{indices},
                }
            } @{ $testcase->{expected} }
            ],
            $testcase->{description};
    }
};

subtest extract_cashtags => sub {
    my $testcases = $yaml->[0]->{tests}->{cashtags};

    for my $testcase (@$testcases) {
        my $parse_result = extract_cashtags($testcase->{text});
        my $expected     = $testcase->{expected};
        is(
            $parse_result,
            $expected,
            $testcase->{description},
        );
    }
};

subtest extract_cashtags_with_indices => sub {
    my $testcases = $yaml->[0]->{tests}->{cashtags_with_indices};

    for my $testcase (@$testcases) {
        my $parse_result = extract_cashtags_with_indices($testcase->{text});
        is(
            $parse_result,
            $testcase->{expected},
            $testcase->{description},
        );
    }

    is(
        extract_cashtags_with_indices(''),
        [],
        'No cashtags from empty string',
    );
};

done_testing;
