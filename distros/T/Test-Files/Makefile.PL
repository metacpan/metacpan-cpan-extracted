use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline portable recursion );

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	ABSTRACT         => 'A Test::Builder based Perl module to ease testing with files and dirs.',
	AUTHOR           => 'Jurij Fajnberg <fajnbergj@gmail.com>',
	DISTNAME         => 'Test-Files',
	LICENSE          => 'perl',
	MIN_PERL_VERSION => '5.014',
	NAME             => 'Test::Files',
	PREREQ_PM        => {
		'Const::Fast'    => 0,
		'Cwd'            => 0,
		'Data::Compare'  => 0,
		'Exporter'       => 0,
		'Fcntl'          => 0,
		'PadWalker'      => 0,
		'Path::Tiny'     => '0.144',
		'Test::Builder'  => 0,
		'Text::Diff'     => 0,
	},
	TEST_REQUIRES    => {
		'File::Copy::Recursive' => 0,
		'FindBin'        				=> 0,
		'Test::Expander' 				=> 0,
		'Test::Simple'   				=> 0,
	},
	VERSION_FROM     => 'lib/Test/Files.pm',
	test             => {
		TESTS            => 't/*/*/*.t',
	},
	META_MERGE       => {
		'meta-spec'      => { version => 2 },
		resources        => {
			repository => {
				type => 'git',
				url  => 'git://github.com/jsf116/Test-Files.git',
				web  => 'https://github.com/jsf116/Test-Files',
			},
			bugtracker => {
				web  => 'https://github.com/jsf116/Test-Files/issues'
			},
		},
	},
);
