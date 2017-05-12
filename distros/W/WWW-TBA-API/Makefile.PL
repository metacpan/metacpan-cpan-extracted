use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::TBA::API',
    AUTHOR              => 'Scott Lawrence <bytbox@gmail.com>',
    VERSION_FROM        => 'lib/WWW/TBA/API.pm',
    ABSTRACT_FROM       => 'lib/WWW/TBA/API.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-TBA-API-*' },
);
