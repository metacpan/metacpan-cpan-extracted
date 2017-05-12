use ExtUtils::MakeMaker;


WriteMakefile(
    NAME          => 'Text::Aspell',
    VERSION_FROM  => 'Aspell.pm',
    LIBS          => ['-laspell'],
    XSPROTOARG    => '-noprototypes',
    PREREQ_PM     => {
        'Test::More'    => 0,
    },
);
