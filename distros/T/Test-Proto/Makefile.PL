use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Test::Proto',
	AUTHOR        => q{Daniel Perrett <perrettdl@googlemail.com>},
	VERSION_FROM  => 'lib/Test/Proto/Base.pm',
	ABSTRACT_FROM => 'lib/Test/Proto.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
		? ('LICENSE'=> 'perl')
		: ()),
	PL_FILES            => {},
	PREREQ_PM           => {
		'Test::More' => 0,
		'Data::Dumper' => 0,
		'Moo' => 0,
		'Object::ID' => '0.0.5',
		'Scalar::Util' => '1.14',
		'Test::Deep::NoTest' => 0
	},
	META_MERGE    => {
		resources => {
			repository => 'http://github.com/pdl/Test-Proto',
			bugtracker => 'http://github.com/pdl/Test-Proto/issues',
			homepage   => 'http://github.com/pdl/Test-Proto',
		},
	},
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean             => { FILES => 'Test-Proto-*' },
);
