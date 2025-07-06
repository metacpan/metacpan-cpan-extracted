use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'ThreatDetector',
    VERSION_FROM => 'lib/ThreatDetector/ThreatDetector.pm',
    AUTHOR => 'Jason Hall <jason.kei.hall@gmail.com>',
    ABSTRACT => 'Modular Apache Log Threat Detection for Vicidial',
    LICENSE => 'perl',
    EXE_FILES => ['bin/detect.pl'],
    PREREQ_PM => {
    'File::Slurp' => 0,
    'IO::Scalar' => 0,
    'IPC::System::Simple' => 0,
    'JSON' => 0,
    'URI::Escape' => 0,
},
    META_MERGE => {
        resources => {
            repository => 'https://github.com/Jkhall81/apache-threat-detector',
        },
    },
);