use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Shorten::ShadyURL',
    AUTHOR              => q{Jason McManus <infidel AT cpan.org>},
    VERSION_FROM        => 'lib/WWW/Shorten/ShadyURL.pm',
    ABSTRACT_FROM       => 'lib/WWW/Shorten/ShadyURL.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PRINT        => 1,
    PREREQ_PM => {
        'Test::More'    => 0,
        'WWW::Shorten'  => '1.90',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Shorten-ShadyURL-*' },
);
