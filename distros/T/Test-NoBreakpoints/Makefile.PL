use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'Test::NoBreakpoints',
    DISTNAME => 'Test-NoBreakpoints',
    ABSTRACT_FROM => 'lib/Test/NoBreakpoints.pm',
    VERSION_FROM => 'lib/Test/NoBreakpoints.pm',
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.52',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.52',
    },
    PREREQ_PM => {
        'Exporter' => 0,
        'File::Find' => 0,
        'File::Spec' => 0,
        'Test::Builder' => 0,
        'strict' => 0,
        'vars' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.92',
        'Test::Tester' => '0.09',
        'File::Find' => 0,
        'Test::UseAllModules' => 0,
        'lib' => 0,
        'warnings' => 0,
    },
    test => {
        'TESTS' => 't/*.t t/baz/*.t',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'http://github.com/renderorange/Test-NoBreakpoints/issues',
            },
            repository => {
                type => 'git',
                url  => 'git://github.com/renderorange/Test-NoBreakpoints.git',
                web  => 'https://github.com/renderorange/Test-NoBreakpoints',
            },
        },
    },
    LICENSE => 'perl',
    AUTHOR => "James FitzGibbon <jfitz\@cpan.org>, Apocalypse <APOCAL\@cpan.org>, Chisel <chisel\@chizography.net>",
);
