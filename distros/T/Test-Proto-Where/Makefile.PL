use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Test::Proto::Where',
	AUTHOR              => q{Daniel Perrett <perrettdl@googlemail.com>},
	VERSION_FROM        => 'lib/Test/Proto/Where.pm',
	ABSTRACT_FROM       => 'lib/Test/Proto/Where.pm',
		($ExtUtils::MakeMaker::VERSION >= 6.3002
		? ('LICENSE'=> 'perl')
		: ()),
	PL_FILES            => {},
	PREREQ_PM => {
		'Test::More' => 0,
		'Test::Proto::Base' => '0.020',
	},
	META_MERGE    => {
		resources => {
			repository => 'http://github.com/pdl/Test-Proto-Where',
			bugtracker => 'http://github.com/pdl/Test-Proto-Where/issues',
			homepage   => 'http://github.com/pdl/Test-Proto-Where',
		},
	},

	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Test::Proto::Where-*' },
);
