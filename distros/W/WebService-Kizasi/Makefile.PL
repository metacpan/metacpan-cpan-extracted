use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WebService::Kizasi',
    AUTHOR        => 'DAIBA, Keiichi <daiba@cpan.org>',
    VERSION_FROM  => 'lib/WebService/Kizasi.pm',
    ABSTRACT_FROM => 'lib/WebService/Kizasi.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::Base'            => 0,
        'version'               => 0,
        'Class::Accessor::Fast' => 0,
        'XML::RSS::LibXML'      => 0,
        'LWP'                   => 0,
        'URI::Escape'           => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'lib/WebService/Kizasi.pm-*' },
);
