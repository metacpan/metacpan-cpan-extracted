use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Wappalyzer',
    AUTHOR              => q{Alexander Nalobin <alexander@nalobin.ru>},
    VERSION_FROM        => 'lib/WWW/Wappalyzer.pm',
    ABSTRACT_FROM       => 'lib/WWW/Wappalyzer.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'lib::abs'       => 0,
        'JSON'           => 0,
        'Exporter'       => 0,
        'Regexp::Parser' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Wappalyzer-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/nalobin/WWW-Wappalyzer.git',
                 web  => 'https://github.com/nalobin/WWW-Wappalyzer',
             },
         },
    },
);
