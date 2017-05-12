use strict;
use warnings;
use ExtUtils::MakeMaker;
use inc::ExtUtils::MY_Metafile qw(my_metafile);

my_metafile 'Text::OutdentEdge' => {
	license => 'perl',
	requires => {
		# no requires.
	},
	build_requires => {
		'Test::More' => 0,
	},
};

WriteMakefile(
    NAME                => 'Text::OutdentEdge',
    AUTHOR              => 'YAMASHINA Hio <hio@cpan.org>',
    VERSION_FROM        => 'lib/Text/OutdentEdge.pm',
    ABSTRACT_FROM       => 'lib/Text/OutdentEdge.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-OutdentEdge-*' },
);
