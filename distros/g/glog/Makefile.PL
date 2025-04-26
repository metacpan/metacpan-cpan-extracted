use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'glog',
    VERSION_FROM => 'lib/glog.pm',
    ABSTRACT     => 'Lightweight logging interface using glog::logger',
    AUTHOR       => 'OnEhIppY <domerosoftware@gmail.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Time::HiRes' => 0,
        'POSIX'       => 0,
        'Exporter'    => 0,
        'Test::More'  => 0,
        'gerr'        => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/DomeroSoftware/glog.git',
        },
    },
);
