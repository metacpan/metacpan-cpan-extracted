use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Tk::TipEntry',
    VERSION_FROM      => 'lib/Tk/TipEntry.pm', # finds $VERSION
    ABSTRACT_FROM     => 'lib/Tk/TipEntry.pm', # retrieve abstract from module
    PREREQ_PM         => {
        # e.g., Module::Name => 1.1
        'Test::More' => 0.98,
        'Test::Pod' => 1.45,
        'Tk' => 804,
        'ExtUtils::MakeMaker' => '6.98',
    },
    TEST_REQUIRES => {
        # modules only required for testing
        'Test::More' => '0.98',
        'Test::Pod' => '1.0',
        'Test::Pod::Coverage' => '1.08',
    },
    AUTHOR         => 'Alexander Becker <asb@cpan.org>',
    LICENSE        => 'perl_5',
    dist           => { COMPRESS => "gzip", SUFFIX => "gz" },
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/asb-capfan/Tk-TipEntry',
        },
    },
    MIN_PERL_VERSION => 5.008008,
);
