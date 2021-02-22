use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'Text::Lorem',
    ABSTRACT_FROM => 'lib/Text/Lorem.pm',
    VERSION_FROM => 'lib/Text/Lorem.pm',
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.46',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.46',
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/adeolaawoyemi/Text-Lorem/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/adeolaawoyemi/Text-Lorem.git',
                web  => 'https://github.com/adeolaawoyemi/Text-Lorem',
            },
        },
    },
    LICENSE => 'perl_5',
    AUTHOR => 'Adeola Awoyemi <adeola@fotango.com>',
);
