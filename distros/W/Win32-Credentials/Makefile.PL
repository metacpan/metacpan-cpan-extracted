use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Win32::Credentials',
    AUTHOR           => 'Massimiliano Citterio <mcitterio@cmcps.it>',
    VERSION_FROM     => 'lib/Win32/Credentials.pm',
    ABSTRACT_FROM    => 'lib/Win32/Credentials.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM => {
        'Win32::API' => '0.84',
        'Encode'     => '0',
        'Win32'      => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/mcitterio/Win32-Credentials.git',
                web  => 'https://github.com/mcitterio/Win32-Credentials',
            },
        },
    },
);