use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT      => 'A foolish "find upper lib" pragma',
    AUTHOR        => 'Ryan Willis <code@ryanwillis.com>',
    DISTNAME      => 'ful',
    LICENSE       => 'mit',
    META_MERGE    => {
        'meta-spec'    => { version => 2 },
        dynamic_config => 1,
        resources      => {
            repository => {
                type => 'git',
                url  => 'git://github.com/ryan-willis/p5-ful.git',
                web  => 'https://github.com/ryan-willis/p5-ful',
            },
        },
    },
    PREREQ_PM     => {
        'strict'     => 0,
        'warnings'   => 0,
        'Cwd'        => '3.26',
        'File::Spec' => '3.32',
    },
    TEST_REQUIRES => {
        'Test::Most' => '0.30',
    },
    NAME          => 'ful',
    VERSION_FROM  => 'ful.pm',
    test => { TESTS => 't/*.t t/t2/t3/*.t t/t2/t3/t/*.t' },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);