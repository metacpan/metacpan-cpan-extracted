
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
    'lib/Treex/Block/Read/AlignedSentences.pm',
    'lib/Treex/Block/Read/BaseAlignedReader.pm',
    'lib/Treex/Block/Read/BaseAlignedTextReader.pm',
    'lib/Treex/Block/Read/BaseCoNLLReader.pm',
    'lib/Treex/Block/Read/CoNLLX.pm',
    'lib/Treex/Block/W2A/AnalysisWithAlignedTrees.pm',
    'lib/Treex/Block/W2A/BaseChunkParser.pm',
    'lib/Treex/Block/W2A/ParseMSTperl.pm',
    'lib/Treex/Block/W2A/ResegmentSentences.pm',
    'lib/Treex/Block/W2A/Segment.pm',
    'lib/Treex/Block/W2A/SegmentOnNewlines.pm',
    'lib/Treex/Block/W2A/Tag.pm',
    'lib/Treex/Block/W2A/TagMorphoDiTa.pm',
    'lib/Treex/Block/W2A/Tokenize.pm',
    'lib/Treex/Block/W2A/TokenizeOnWhitespace.pm',
    'lib/Treex/Block/Write/CoNLLX.pm',
    'lib/Treex/Tool/Lexicon/CS.pm',
    'lib/Treex/Tool/ProcessUtils.pm',
    'lib/Treex/Tool/Segment/RuleBased.pm',
    'lib/Treex/Tool/Tagger/Featurama.pm',
    'lib/Treex/Tool/Tagger/MorphoDiTa.pm',
    'lib/Treex/Tool/Tagger/Role.pm',
    'lib/Treex/Unilang.pm',
    't/00-compile.t',
    't/aligned_sentences.t',
    't/author-critic.t',
    't/author-test-eol.t',
    't/base_aligned.t',
    't/base_aligned_text.t',
    't/morphodita.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-minimum-version.t',
    't/release-mojibake.t',
    't/release-no-tabs.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-test-version.t',
    't/release-unused-vars.t',
    't/resegment_sentences.t',
    't/rule_based.t',
    't/segment_on_nl.t',
    't/tokenize.t',
    't/tokenize_on_whitespace.t'
);

notabs_ok($_) foreach @files;
done_testing;
