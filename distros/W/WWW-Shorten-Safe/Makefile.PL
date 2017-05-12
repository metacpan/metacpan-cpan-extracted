use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Shorten::Safe',
    AUTHOR              => 'Julien Sobrier <jsobrier@safe.mn>',
    VERSION_FROM        => 'lib/WWW/Shorten/Safe.pm',
    ABSTRACT_FROM       => 'lib/WWW/Shorten/Safe.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'   => 0,
        'WWW::Shorten' => 3.00,
    },
    PREREQ_PRINT        => 1,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Shorten-Safe-*' },
);
