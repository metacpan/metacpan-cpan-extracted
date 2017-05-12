use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::Kaolabo',
    AUTHOR              => 'Akihito Takeda <takeda.akihito@gmail.com>',
    VERSION_FROM        => 'lib/WebService/Kaolabo.pm',
    ABSTRACT_FROM       => 'lib/WebService/Kaolabo.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'         => 0,
        'version'            => 0,
        'Test::Perl::Critic' => 0,
        'Class::Accessor'    => 0,
        'LWP::UserAgent'     => 0,
        'HTTP::Request'      => 0,
        'Data::Average'      => 0,
        'Imager'             => 0,
        'File::Spec'         => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-Kaolabo-*' },
);
