use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::FileEntry',
    VERSION_FROM      => 'lib/Tk/FileEntry.pm', # finds $VERSION
    ABSTRACT_FROM     => 'lib/Tk/FileEntry.pm', # retrieve abstract from module
    PREREQ_PM         => {
        # e.g., Module::Name => 1.1
        'ExtUtils::MakeMaker' => '6.64',
        'Tk' => '804.030',
    },
    TEST_REQUIRES => {
        # modules only required for testing
        'Test::More' => '0.98',
        'Test::Pod' => '1.0',
        'Test::Pod::Coverage' => '1.08',
    },
    AUTHOR         => 'Alex Becker <c a p f a n _a-t_ g m x write_Adot-here d e - i n v a l l i d>',
    LICENSE        => 'perl_5',
    dist           => { COMPRESS => "gzip", SUFFIX => "gz" },
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/asb-capfan/Tk-FileEntry',
        },
    },
    MIN_PERL_VERSION => 5.008008,
);
