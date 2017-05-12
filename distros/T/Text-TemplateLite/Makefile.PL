use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::TemplateLite',
    AUTHOR              => q{Brian Katzung <briank@kappacs.com>},
    VERSION_FROM        => 'lib/Text/TemplateLite.pm',
    ABSTRACT_FROM       => 'lib/Text/TemplateLite.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'Carp' => 0,
	'Scalar::Util' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-TemplateLite-*' },
);
