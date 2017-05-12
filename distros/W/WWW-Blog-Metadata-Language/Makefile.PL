use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Blog::Metadata::Language',
    AUTHOR              => 'Darko Obradovic <dobradovic@gmx.de>',
    VERSION_FROM        => 'lib/WWW/Blog/Metadata/Language.pm',
    ABSTRACT_FROM       => 'lib/WWW/Blog/Metadata/Language.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'version'               => 0,
		'WWW::Blog::Metadata'   => 0,
		'Text::Language::Guess' => 0,
  },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Blog-Metadata-Language-*' },
);
