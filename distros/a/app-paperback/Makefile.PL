use 5.010000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'App::paperback',
	VERSION => '1.14',
	MIN_PERL_VERSION => '5.010000',

	EXE_FILES => [
		'bin/paperback',
	],

	PREREQ_PM => {
	},

	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			license => 'https://dev.perl.org/licenses',
			bugtracker => {
				web => 'https://github.com/hectormonacci/perl-app-paperback/issues',
			},
			repository => {
				type => 'git',
				url => 'https://github.com/hectormonacci/perl-app-paperback.git',
				web => 'https://github.com/hectormonacci/perl-app-paperback',
			},
		},
	},

	ABSTRACT => 'Perl program and module for page imposition',
	AUTHOR   => 'Hector M. Monacci <hector.monacci@gmail.com>',
	LICENSE  => 'perl',
);
