use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'OGDL::Parser',
    VERSION_FROM      => 'Parser.pm', # finds $VERSION
    ABSTRACT_FROM => 'Parser.pm',
    EXE_FILES     => [ qw(pgpath) ],
    dist          => {
        'COMPRESS'  => 'gzip -9v',
        'SUFFIX'    => '.gz',
    },
);

