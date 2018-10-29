#!/usr/bin/env perl
use ExtUtils::MakeMaker 6.52;  # need >=6.52 for CONFIGURE_REQUIRES
# and in CONFIGURE_REQUIRES, we require >=6.64 for TEST_REQUIRES
WriteMakefile(
	NAME           => 'Tie::Subset',
	AUTHOR         => 'Hauke D <haukex@zero-g.net>',
	LICENSE        => 'perl_5',
	VERSION_FROM   => 'lib/Tie/Subset.pm', # finds $VERSION
	ABSTRACT_FROM  => 'lib/Tie/Subset.pm',
	MIN_PERL_VERSION => '5.6.0',
	META_MERGE     => {
		'meta-spec'  => { version => 2 },
		provides     => {
			'Tie::Subset' => {
				file    => 'lib/Tie/Subset.pm',
				version => '0.01',
			},
			'Tie::Subset::Hash' => {
				file    => 'lib/Tie/Subset/Hash.pm',
				version => '0.01',
			},
			'Tie::Subset::Array' => {
				file    => 'lib/Tie/Subset/Array.pm',
				version => '0.01',
			},
		},
		resources    => {
			homepage    => 'https://github.com/haukex/Tie-Subset',
			repository  => {
				type       => 'git',
				url        => 'https://github.com/haukex/Tie-Subset.git',
				web        => 'https://github.com/haukex/Tie-Subset',
			},
			bugtracker  => {
				web        => 'https://github.com/haukex/Tie-Subset/issues',
				#mailto     => '',
			},
		},
		prereqs      => {
			runtime    => {
				recommends => { # "strongly encouraged and should be satisfied except in resource constrained environments"
				},
				suggests   => { # "optional, but are suggested for enhanced operation"
				},
			},
		},
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker'    => '6.64',
	},
	PREREQ_PM      => {
		# CPAN - none
		# Perl core modules
		'Carp'                   => 0,
		'warnings::register'     => 0,
	},
	TEST_REQUIRES  => {
		# CPAN - none
		# Perl core modules
		'Test::More'             => '1.302096',
		'Exporter'               => 0,
		'FindBin'                => 0,
		# note I haven't included modules needed for author tests here
	},
);
