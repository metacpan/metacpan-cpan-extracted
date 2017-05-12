use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::EP3',
    AUTHOR              => 'Gary Spivey <spivey@ieee.org>',
    VERSION_FROM        => 'lib/Text/EP3.pm',
    ABSTRACT            => 'The Extensible Perl PreProcessor',
    PL_FILES            => {},
    EXE_FILES           => ['bin/ep3'], 
    PREREQ_PM => {
#        'Test::More' => 0,
        'Exporter' => 0,
        'FileHandle' => 0,
        'Getopt::Long' => 0,
        'Cwd' => 0,
        'Carp' => 0,
        'AutoLoader' => 0,
        'Env' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-EP3-*' },
);
