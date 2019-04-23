
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'X::Tiny',
    VERSION_FROM => 'lib/X/Tiny.pm',            # finds \$VERSION
    AUTHOR       => 'Felipe Gasper',
    ABSTRACT     => 'Super-lightweight exception framework',
    LICENSE      => 'perl',

    MIN_PERL_VERSION => 5.010000,

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/FGasper/p5-X-Tiny.git',
                web  => 'https://github.com/FGasper/p5-X-Tiny',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-X-Tiny/issues',
            },
        },
    },

    PREREQ_PM    => {
        'Module::Runtime' => 0,
        'overload' => 0,
    },

    TEST_REQUIRES => {
        'parent'          => 0,
        'Test::More'      => 0,
        'Test::Simple'    => 0,
    },
);

