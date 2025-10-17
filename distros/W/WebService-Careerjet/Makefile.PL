use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::Careerjet',
    AUTHOR              => 'Thomas Busch <api@careerjet.com>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/WebService/Careerjet.pm',
    ABSTRACT_FROM       => 'lib/WebService/Careerjet.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Class::AutoAccess' => 0.02,
        'Encode' => 2.08,
        'Test::More' => 0,
        'URI::Escape' => 3.28,
        'LWP::UserAgent' => 2.033,
        'HTTP::Request'  => 1.40,
        'Carp'           => 1.03,
        'JSON'           => 2.07,
        'Getopt::Std'    => 1.05,
        'Text::Wrap'     => 2001.09292
        
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-Careerjet-*' },
);
