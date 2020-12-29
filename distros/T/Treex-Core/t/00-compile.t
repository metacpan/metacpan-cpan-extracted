use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 70 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Treex.pm',
    'Treex/Block/Read/BaseReader.pm',
    'Treex/Block/Read/BaseSplitterRole.pm',
    'Treex/Block/Read/BaseTextReader.pm',
    'Treex/Block/Read/Sentences.pm',
    'Treex/Block/Read/Text.pm',
    'Treex/Block/Read/Treex.pm',
    'Treex/Block/Util/DefinedAttr.pm',
    'Treex/Block/Util/Eval.pm',
    'Treex/Block/Util/Find.pm',
    'Treex/Block/Util/FixInvalidIDs.pm',
    'Treex/Block/Util/SetGlobal.pm',
    'Treex/Block/Write/BaseTextWriter.pm',
    'Treex/Block/Write/BaseWriter.pm',
    'Treex/Block/Write/Sentences.pm',
    'Treex/Block/Write/Text.pm',
    'Treex/Block/Write/Treex.pm',
    'Treex/Core.pm',
    'Treex/Core/Block.pm',
    'Treex/Core/Bundle.pm',
    'Treex/Core/BundleZone.pm',
    'Treex/Core/CacheBlock.pm',
    'Treex/Core/Common.pm',
    'Treex/Core/Config.pm',
    'Treex/Core/DocZone.pm',
    'Treex/Core/Document.pm',
    'Treex/Core/DocumentReader.pm',
    'Treex/Core/DocumentReader/Base.pm',
    'Treex/Core/DocumentReader/ZoneReader.pm',
    'Treex/Core/Files.pm',
    'Treex/Core/Loader.pm',
    'Treex/Core/Log.pm',
    'Treex/Core/Node.pm',
    'Treex/Core/Node/A.pm',
    'Treex/Core/Node/Aligned.pm',
    'Treex/Core/Node/EffectiveRelations.pm',
    'Treex/Core/Node/InClause.pm',
    'Treex/Core/Node/Interset.pm',
    'Treex/Core/Node/N.pm',
    'Treex/Core/Node/Ordered.pm',
    'Treex/Core/Node/P.pm',
    'Treex/Core/Node/T.pm',
    'Treex/Core/Phrase.pm',
    'Treex/Core/Phrase/BaseNTerm.pm',
    'Treex/Core/Phrase/Builder.pm',
    'Treex/Core/Phrase/Coordination.pm',
    'Treex/Core/Phrase/NTerm.pm',
    'Treex/Core/Phrase/PP.pm',
    'Treex/Core/Phrase/Term.pm',
    'Treex/Core/RememberArgs.pm',
    'Treex/Core/Resource.pm',
    'Treex/Core/Run.pm',
    'Treex/Core/Scenario.pm',
    'Treex/Core/ScenarioParser.pm',
    'Treex/Core/TredView.pm',
    'Treex/Core/TredView/AnnotationCommand.pm',
    'Treex/Core/TredView/BackendStorable.pm',
    'Treex/Core/TredView/Colors.pm',
    'Treex/Core/TredView/Common.pm',
    'Treex/Core/TredView/Labels.pm',
    'Treex/Core/TredView/LineStyles.pm',
    'Treex/Core/TredView/Styles.pm',
    'Treex/Core/TredView/TreeLayout.pm',
    'Treex/Core/TredView/Vallex.pm',
    'Treex/Core/Types.pm',
    'Treex/Core/WildAttr.pm',
    'Treex/Core/Zone.pm',
    'Treex/Tool/Probe.pm'
);

my @scripts = (
    'bin/treex',
    'bin/ttred'
);

# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    @switches = (@switches, split(' ', $1)) if $1;

    close $fh and skip("$file uses -T; not testable with PERL5LIB", 1)
        if grep { $_ eq '-T' } @switches and $ENV{PERL5LIB};

    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-c', $file))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


