use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# the uShuffle library needs random() and srandom(), which Windows lacks;
# exit 0 makes CPAN testers report "not applicable" rather than a failure
if ($^O eq 'MSWin32') {
    print "OS unsupported\n";
    exit 0;
}

my $version = MM->parse_version('lib/Ushuffle.pm');
my %test_requires = ('Test::More' => '0.88');    # done_testing

WriteMakefile(
    NAME             => 'Ushuffle',
    VERSION_FROM     => 'lib/Ushuffle.pm',
    ABSTRACT_FROM    => 'lib/Ushuffle.pm',
    AUTHOR           => 'Michael T. Wolfinger <michael@wolfinger.eu>',
    LICENSE          => 'bsd',
    MIN_PERL_VERSION => '5.010001',
    # TEST_REQUIRES needs ExtUtils::MakeMaker 6.64; older ones take the
    # module as an ordinary prerequisite
    ($ExtUtils::MakeMaker::VERSION >= 6.64
        ? (PREREQ_PM => {}, TEST_REQUIRES => \%test_requires)
        : (PREREQ_PM => \%test_requires)),
    LIBS             => ['-lm'],
    INC              => '-I.',
    # Ushuffle.xs plus ushuffle_lib.c, which pulls in ushufflelib/ushuffle.c
    OBJECT           => '$(O_FILES)',
    depend           => {
        'ushuffle_lib$(OBJ_EXT)' => 'ushufflelib/ushuffle.c ushufflelib/ushuffle.h',
        'Ushuffle$(OBJ_EXT)'     => 'ushufflelib/ushuffle.h',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        keywords    => [
            'bioinformatics', 'sequence shuffling', 'k-let', 'k-mer',
            'dinucleotide shuffling', 'RNA', 'DNA', 'null model', 'uShuffle',
        ],
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/mtw/ushuffle-perl.git',
                web  => 'https://github.com/mtw/ushuffle-perl',
            },
            bugtracker => { web => 'https://github.com/mtw/ushuffle-perl/issues' },
        },
        # Ushuffle::Shuffler is defined in the XS file, where the indexer
        # would not find it
        provides => {
            'Ushuffle'           => { file => 'lib/Ushuffle.pm', version => $version },
            'Ushuffle::Shuffler' => { file => 'lib/Ushuffle.pm', version => $version },
        },
    },
);
