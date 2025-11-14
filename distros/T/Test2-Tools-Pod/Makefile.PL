use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Test2::Tools::Pod',
    VERSION_FROM => 'lib/Test2/Tools/Pod.pm',

    MIN_PERL_VERSION => 'v5.42',

    PREREQ_PM => {
        'Path::Iterator::Rule' => '1.015',
        'Path::Tiny' => '0.150',
    },

    META_MERGE => {
        resources => {
            repository => 'https://github.com/tessarin/Test2-Tools-Pod',
            bugtracker => 'https://github.com/tessarin/Test2-Tools-Pod/issues',
        },
    },

    LICENSE => 'mit',
    clean => { FILES => 'cover_db' },
);
