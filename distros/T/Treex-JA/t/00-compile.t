use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.042

use Test::More  tests => 12 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'Treex/Block/W2A/JA/FixCopulas.pm',
    'Treex/Block/W2A/JA/FixInterpunction.pm',
    'Treex/Block/W2A/JA/ParseJDEPP.pm',
    'Treex/Block/W2A/JA/RehangAuxVerbs.pm',
    'Treex/Block/W2A/JA/RehangConjunctions.pm',
    'Treex/Block/W2A/JA/RehangCopulas.pm',
    'Treex/Block/W2A/JA/RehangParticles.pm',
    'Treex/Block/W2A/JA/RomanizeTags.pm',
    'Treex/Block/W2A/JA/TagMeCab.pm',
    'Treex/JA.pm',
    'Treex/Tool/Parser/JDEPP.pm',
    'Treex/Tool/Tagger/MeCab.pm'
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


