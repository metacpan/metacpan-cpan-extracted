use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::TemplateLite::Standard',
    AUTHOR              => q{Brian Katzung <briank@kappacs.com>},
    VERSION_FROM        => 'lib/Text/TemplateLite/Standard.pm',
    ABSTRACT_FROM       => 'lib/Text/TemplateLite/Standard.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'Scalar::Util' => 0,
        'Test::More' => 0,
	'Text::TemplateLite' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-TemplateLite-Standard-*' },
);
