use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline portable recursion );

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	ABSTRACT         => 'Expansion of test functionalities that appear to be frequently used while testing.',
	AUTHOR           => 'Jurij Fajnberg <fajnbergj@gmail.com>',
	DISTNAME         => 'Test-Expander',
	LICENSE          => 'perl',
	MIN_PERL_VERSION => '5.014',
	NAME             => 'Test::Expander',
	PREREQ_PM        => {
		'B'                     => 0,
		'Const::Fast'           => 0,
		'Exporter'              => 0,
		'File::chdir'           => 0,
		'File::Temp'            => 0,
		'Getopt::Long'          => 0,
		'Importer'              => 0,
		'PadWalker'             => 0,
		'Path::Tiny'            => '0.144',
		'Scalar::Readonly'      => 0,
		'Test::Builder' 				=> 0,
		'Test2::API'   					=> 0,
		'Test2::Tools::Basic'   => 0,
		'Test2::Tools::Explain' => 0,
		'Test2::Tools::Subtest' => 0,
		'Test2::V0'             => 0,
	},
	TEST_REQUIRES    => {
		'FindBin'               => 0,
		'Test::Simple'          => 0,
	},
	VERSION_FROM     => 'lib/Test/Expander.pm',
	test             => {
		TESTS                   => 't/*/*/*.t t/*/*/*/*.t',
	},
	META_MERGE       => {
		'meta-spec'             => { version => 2 },
		resources               => {
			repository              => {
				type                    => 'git',
				url                     => 'git://github.com/jsf116/Test-Expander.git',
				web                     => 'https://github.com/jsf116/Test-Expander',
			},
			bugtracker              => {
				web                     => 'https://github.com/jsf116/Test-Expander/issues'
			},
		},
	},
);
