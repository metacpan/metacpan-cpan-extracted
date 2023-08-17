use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	NAME               => 'Virani',
	AUTHOR             => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM       => 'lib/Virani.pm',
	ABSTRACT_FROM      => 'lib/Virani.pm',
	LICENSE            => 'lgpl_2_1',
	MIN_PERL_VERSION   => '5.006',
	INST_SCRIPT        => 'bin',
	EXE_FILES          => [ 'src_bin/virani', 'src_bin/mojo-virani' ],
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'Mojolicious::Lite'             => '0',
		'TOML'                          => '0',
		'Net::Subnet'                   => '0',
		'JSON'                          => '0',
		'TOML'                          => '0',
		'File::Slurp'                   => '0',
		'Net::Subnet'                   => '0',
		'File::Find::IncludesTimeRange' => '0.2.0',
		'File::Find::Rule'              => '0',
		'Digest::MD5'                   => '0',
		'File::Spec'                    => '0',
		'IPC::Cmd'                      => '0',
		'File::Copy'                    => '0',
		'Sys::Syslog'                   => '0',
		'LWP::UserAgent'                => '0',
		'HTTP::Request::Common'         => '0',
		'Time::Piece::Guess'            => '0.1.0',
	},
	dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean      => { FILES    => 'Virani-*' },
	META_MERGE => {
		"meta-spec" => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => 'git@github.com:LilithSec/Virani.git',
				web  => 'https://github.com/LilithSec/Virani',
			},
		},
	}
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless ( eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 } ) {
	my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
	@{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$test_requires } = values %$test_requires;
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 } ) {
	my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
	@{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$build_requires } = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
	unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
	unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
	unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
