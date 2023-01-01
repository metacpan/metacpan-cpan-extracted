use 5.035010;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Test::Named',
    VERSION_FROM      => 'lib/Test/Named.pm',
    PREREQ_PM         => { },
    BUILD_REQUIRES    => {
        "Test::More"  => 0,
    },
    ABSTRACT_FROM     => 'lib/Test/Named.pm',
    AUTHOR            => 'Alejandro Imass <alejandroimass@nonet>',
    LICENSE           => 'artistic_2',
    META_MERGE        => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/aimass/Test-Named',
                web => 'https://github.com/aimass/Test-Named',
            },
        },
    },
);
