use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'VANAMBURG::SEMPROG::SimpleGraph',
    AUTHOR              => 'Gordon Van Amburg <vanamburg@cpan.org>',
    VERSION_FROM        => 'lib/VANAMBURG/SEMPROG/SimpleGraph.pm',
    ABSTRACT       => 'A Perl companion "Programming The Semantic Web"',
    PL_FILES            => {},
    PREREQ_PM => {
	'JSON' => 0,
        'Test::More' => 0,
	'Text::CSV_XS' => 0,
	'Moose' => 0.93,
	'Set::Scalar' => 0,
	'List::MoreUtils' => 0,
	'Moose::Role' => 0,
	'Modern::Perl' => 1.03,
	'LWP::Simple' => 0,
	'URI::Escape' => 0,
	'File::Slurp' => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'VANAMBURG-SEMPROG-*' },
);
