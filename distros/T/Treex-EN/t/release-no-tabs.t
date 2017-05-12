
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Treex/Block/W2A/EN/FixTags.pm',
    'lib/Treex/Block/W2A/EN/FixTagsAfterParse.pm',
    'lib/Treex/Block/W2A/EN/FixTokenization.pm',
    'lib/Treex/Block/W2A/EN/Lemmatize.pm',
    'lib/Treex/Block/W2A/EN/NormalizeForms.pm',
    'lib/Treex/Block/W2A/EN/ParseMSTperl.pm',
    'lib/Treex/Block/W2A/EN/SetIsMemberFromDeprel.pm',
    'lib/Treex/Block/W2A/EN/TagLinguaEn.pm',
    'lib/Treex/Block/W2A/EN/TagMorphoDiTa.pm',
    'lib/Treex/Block/W2A/EN/Tokenize.pm',
    'lib/Treex/EN.pm',
    'lib/Treex/Tool/EnglishMorpho/Analysis.pm',
    'lib/Treex/Tool/EnglishMorpho/Lemmatizer.pm',
    'lib/Treex/Tool/Segment/EN/RuleBased.pm',
    'lib/Treex/Tool/Tagger/Featurama/EN.pm',
    't/00-compile.t',
    't/author-critic.t',
    't/author-test-eol.t',
    't/contractions.txt',
    't/featurama_en.t',
    't/lingua_en.t',
    't/morpho.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-minimum-version.t',
    't/release-mojibake.t',
    't/release-no-tabs.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-test-version.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
