use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/WebService/GrowthBook.pm',
    'lib/WebService/GrowthBook/AbstractFeatureCache.pm',
    'lib/WebService/GrowthBook/AbstractFeatureCache.pod',
    'lib/WebService/GrowthBook/CacheEntry.pm',
    'lib/WebService/GrowthBook/CacheEntry.pod',
    'lib/WebService/GrowthBook/Eval.pm',
    'lib/WebService/GrowthBook/Experiment.pm',
    'lib/WebService/GrowthBook/Feature.pm',
    'lib/WebService/GrowthBook/FeatureRepository.pm',
    'lib/WebService/GrowthBook/FeatureRepository.pod',
    'lib/WebService/GrowthBook/FeatureResult.pm',
    'lib/WebService/GrowthBook/FeatureResult.pod',
    'lib/WebService/GrowthBook/FeatureRule.pm',
    'lib/WebService/GrowthBook/InMemoryFeatureCache.pm',
    'lib/WebService/GrowthBook/InMemoryFeatureCache.pod',
    'lib/WebService/GrowthBook/Result.pm',
    'lib/WebService/GrowthBook/Util.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/cases.json',
    't/feature.t',
    't/feature_repository.t',
    't/feature_result.t',
    't/feature_rule.t',
    't/growthbook.t',
    't/in_memroy_feature_cache.t',
    't/rc/perlcriticrc',
    't/rc/perltidyrc',
    't/test_cases.t',
    't/test_data_growthbook.json',
    'xt/author/critic.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/test-version.t',
    'xt/release/common_spelling.t',
    'xt/release/cpan-changes.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
