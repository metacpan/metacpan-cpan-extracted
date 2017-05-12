use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'YAML::Parser::Syck',
    VERSION_FROM => 'Syck.pm',
    LIBS => ['-lsyck'],
    DEFINE => '',
    INC => '-I.',
);
