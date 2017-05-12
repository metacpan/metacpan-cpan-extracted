use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Pfacter',
    ABSTRACT            => 'Collect and display facts about the system',
    AUTHOR              => 'Scott Schneider <sschneid@gmail.com>',
    VERSION_FROM        => 'pfacter',
    PL_FILES            => {},
    PREREQ_PM => {
        'Getopt::Long' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

