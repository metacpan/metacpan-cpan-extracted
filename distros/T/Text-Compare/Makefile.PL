use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Compare',
    AUTHOR              => 'Serguei Trouchelle <stro@railways.dp.ua>, Marcus Thiesen <marcus@thiesen.org>',
    VERSION_FROM        => 'lib/Text/Compare.pm',
    ABSTRACT_FROM       => 'lib/Text/Compare.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,

	'Lingua::Identify' => 0,
	'Lingua::StopWords' => 0,
	'Lingua::Stem' => 0,

	'Sparse::Vector' => 0,

	'Carp' => 0,

	'Memoize' => 0,
	'HTML::Strip' => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Compare-*' },
);
