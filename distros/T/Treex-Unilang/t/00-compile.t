use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.045

use Test::More  tests => 23 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'Treex/Block/Read/AlignedSentences.pm',
    'Treex/Block/Read/BaseAlignedReader.pm',
    'Treex/Block/Read/BaseAlignedTextReader.pm',
    'Treex/Block/Read/BaseCoNLLReader.pm',
    'Treex/Block/Read/CoNLLX.pm',
    'Treex/Block/W2A/AnalysisWithAlignedTrees.pm',
    'Treex/Block/W2A/BaseChunkParser.pm',
    'Treex/Block/W2A/ParseMSTperl.pm',
    'Treex/Block/W2A/ResegmentSentences.pm',
    'Treex/Block/W2A/Segment.pm',
    'Treex/Block/W2A/SegmentOnNewlines.pm',
    'Treex/Block/W2A/Tag.pm',
    'Treex/Block/W2A/TagMorphoDiTa.pm',
    'Treex/Block/W2A/Tokenize.pm',
    'Treex/Block/W2A/TokenizeOnWhitespace.pm',
    'Treex/Block/Write/CoNLLX.pm',
    'Treex/Tool/Lexicon/CS.pm',
    'Treex/Tool/ProcessUtils.pm',
    'Treex/Tool/Segment/RuleBased.pm',
    'Treex/Tool/Tagger/Featurama.pm',
    'Treex/Tool/Tagger/MorphoDiTa.pm',
    'Treex/Tool/Tagger/Role.pm',
    'Treex/Unilang.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};


