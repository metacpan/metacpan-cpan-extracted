use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Text::Indent',
    ABSTRACT_FROM => 'lib/Text/Indent.pm',
    VERSION_FROM => 'lib/Text/Indent.pm',
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.46',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.46',
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Class::MethodMaker' => '1.12',
        'Params::Validate' => '0.5',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/renderorange/Text-Indent/issues',
            },
        },
    },
    LICENSE => 'perl_5',
    AUTHOR => 'James FitzGibbon, <jfitz@CPAN.org>',
);
