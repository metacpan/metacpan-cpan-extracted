use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Filter::URI',
    AUTHOR              => 'Moritz Onken <onken@houseofdesign.de>',
    VERSION_FROM        => 'lib/Text/Filter/URI.pm',
    ABSTRACT_FROM       => 'lib/Text/Filter/URI.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Text::Unidecode' => 0,
	'Text::Filter' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Filter-URI-*' },
);
