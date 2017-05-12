#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $vcs = 'https://github.com/olof/Text-FileTree';

WriteMakefile (
	NAME => 'Text::FileTree',
	AUTHOR => 'Olof Johansson <olof@cpan.org>',
	LICENSE => 'perl',
	ABSTRACT_FROM => 'lib/Text/FileTree.pm',
	VERSION_FROM => 'lib/Text/FileTree.pm',
	MIN_PERL_VERSION => '5.8.0',
	SIGN => 1,

	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => "$vcs.git",
				web => "$vcs",
			},
			bugtracker  => {
				web    => "$vcs/issues",
			},
		},
	},

	BUILD_REQUIRES => {
		# This is actually a test requirement, but I don't want
		# to bump the EU::MM dep all the way to 6.64 just yet.
		'Test::Perl::Critic' => 0,

		# This is for uh, documentation. EU::MM won't be able
		# to understand this if you aren't using 6.56 or later,
		# since that's when BUILD_REQUIRES was introduced.
		'ExtUtils::MakeMaker' => 6.56,
	},

	PREREQ_PM => {
		'File::Slurp' => 0,
		'Module::Load' => 0,
	},
);
