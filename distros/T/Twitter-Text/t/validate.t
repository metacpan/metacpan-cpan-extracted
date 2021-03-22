use Test2::V0;
no if $^V lt v5.13.9, 'warnings', 'utf8'; ## no critic (ValuesAndExpressions::ProhibitMismatchedOperators)
BEGIN {
    eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        require Test2::Plugin::GitHub::Actions::AnnotateFailedTest;
        Test2::Plugin::GitHub::Actions::AnnotateFailedTest->import;
    };
}

use Twitter::Text::Util;
use Twitter::Text::Configuration;
use Twitter::Text;

sub expected_parse_result {
    my $testcase = shift;
    return hash {
        field weighted_length => $testcase->{expected}->{weightedLength};
        field valid           => bool($testcase->{expected}->{valid});
        field permillage      => $testcase->{expected}->{permillage};
        # Note that we don't assert display and valid ranges
        #field display_range_start => $testcase->{expected}->{displayRangeStart};
        #field display_range_end => $testcase->{expected}->{displayRangeEnd};
        #field valid_range_start => $testcase->{expected}->{validRangeStart};
        #field valid_range_end => $testcase->{expected}->{validRangeEnd};
        field display_range_start => E;
        field display_range_end   => E;
        field valid_range_start   => E;
        field valid_range_end     => E;
        etc;
    };
}

# XXX: "Unicode non-character 0xffff is illegal for interchange" warning occurs in YAML::PP::Lexer in Perl between v5.10.0 and v5.13.8
# so we want to import Test2::Plugin::NoWarnings after reading YAML files.
# https://perldoc.perl.org/5.14.2/perl5139delta#Selected-Bug-Fixes
my $yaml = load_yaml("validate.yml");
require Test2::Plugin::NoWarnings;
Test2::Plugin::NoWarnings->import;

subtest tweets => sub {
    my $testcases = $yaml->[0]->{tests}->{tweets};

    for my $testcase (@$testcases) {
        my $validation_result = is_valid_tweet(
            $testcase->{text},
            {
                config => Twitter::Text::Configuration::V2,
            }
        );
        is $validation_result, bool($testcase->{expected}), $testcase->{description};
    }
};

subtest hashtags => sub {
    my $testcases = $yaml->[0]->{tests}->{hashtags};

    for my $testcase (@$testcases) {
        my $validation_result = is_valid_hashtag($testcase->{text});
        is $validation_result, bool($testcase->{expected}), $testcase->{description};
    }

    ok !is_valid_hashtag(''), 'Empty string is not a valid hashtag';
};

subtest lists => sub {
    my $testcases = $yaml->[0]->{tests}->{lists};

    for my $testcase (@$testcases) {
        my $validation_result = is_valid_list($testcase->{text});
        is $validation_result, bool($testcase->{expected}), $testcase->{description};
    }

    ok !is_valid_list(''), 'Empty string is not a valid list';
};

subtest urls => sub {
    my $testcases = $yaml->[0]->{tests}->{urls};

    for my $testcase (@$testcases) {
        my $validation_result = is_valid_url($testcase->{text});
        is $validation_result, bool($testcase->{expected}), $testcase->{description};
    }

    ok !is_valid_url(''), 'Empty string is not a valid URL';
    ok !is_valid_url('https://こんにちは.みんな/', unicode_domains => 0), 'Unicode domain disabled (invalid)';
    ok is_valid_url('https://example.com/', unicode_domains => 0), 'Unicode domain disabled (valid)';
};

subtest urls_without_protocol => sub {
    my $testcases = $yaml->[0]->{tests}->{urls_without_protocol};

    for my $testcase (@$testcases) {
        my $validation_result = is_valid_url($testcase->{text}, require_protocol => 0);
        is $validation_result, bool($testcase->{expected}), $testcase->{description}, $testcase->{text};
    }

    ok !is_valid_url('', require_protocol => 0), 'Empty string is not a valid URL';
};

subtest usernames => sub {
    my $testcases = $yaml->[0]->{tests}->{usernames};

    for my $testcase (@$testcases) {
        my $validation_result = is_valid_username($testcase->{text});
        is $validation_result, bool($testcase->{expected}), $testcase->{description};
    }

    ok !is_valid_username(''), 'Empty string is not a valid username';
};

subtest WeightedTweetsCounterTest => sub {
    my $testcases = $yaml->[0]->{tests}->{WeightedTweetsCounterTest};

    for my $testcase (@$testcases) {
        my $parse_result = parse_tweet(
            $testcase->{text},
            {
                config => Twitter::Text::Configuration::V2,
            }
        );
        is $parse_result, expected_parse_result($testcase), $testcase->{description};
    }
};

subtest WeightedTweetsWithDiscountedEmojiCounterTest => sub {
    my $testcases = $yaml->[0]->{tests}->{WeightedTweetsWithDiscountedEmojiCounterTest};

    for my $testcase (@$testcases) {
        my $parse_result = parse_tweet($testcase->{text});
        is $parse_result, expected_parse_result($testcase), $testcase->{description};
    }
};

subtest UnicodeDirectionalMarkerCounterTest => sub {
    my $testcases = $yaml->[0]->{tests}->{UnicodeDirectionalMarkerCounterTest};

    for my $testcase (@$testcases) {
        my $parse_result = parse_tweet($testcase->{text});
        is $parse_result, expected_parse_result($testcase), $testcase->{description};
    }
};

done_testing;
