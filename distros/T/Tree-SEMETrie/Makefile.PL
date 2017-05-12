use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Tree::SEMETrie',
	AUTHOR => q{Aaron Cohen <aarondcohen@gmail.com>},
	VERSION_FROM => 'lib/Tree/SEMETrie.pm',
	ABSTRACT_FROM => 'lib/Tree/SEMETrie.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'=> 'perl') : ()),
	PL_FILES => {},
	PREREQ_PM => {
		'Test::Exception' => 0,
		'Test::More' => 0,
	},
	dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Tree-SEMETrie-*' },
);
