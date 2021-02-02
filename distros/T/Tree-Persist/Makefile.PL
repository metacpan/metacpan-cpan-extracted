require 5.006000;

use ExtUtils::MakeMaker;

# ----------------------

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR		=> 'Rob Kinyin <rkinyon@cpan.org>',
		ABSTRACT	=> 'A transparent persistence layer for Tree and its children',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Tree-Persist-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME			=> 'Tree-Persist',
	LICENSE				=> 'perl',
	NAME				=> 'Tree::Persist',
	MIN_PERL_VERSION	=> 5.006,
	PL_FILES			=> {},
	PREREQ_PM			=>
	{
		'base'				=> 0,
		'Module::Runtime'	=> 0.013,
		'Scalar::Util'		=> 1.10,
		'strict'			=> 0,
		'warnings'			=> 0,
		'XML::Parser'		=> 2.41,
	},
	TEST_REQUIRES =>
	{
		'DBD::SQLite'			=> 1.39,
		'DBI'					=> 1.627,
		'File::Slurp'			=> 9999.19,
		'File::Spec'			=> 0.01,
		'File::Spec::Functions'	=> 0.01,
		'File::Temp'			=> 0.01,
		'Test::File'			=> 1.10,
		'Test::File::Contents'	=> 0.02,
		'Test::More'			=> 1.001002,
		'Test::Pod'				=> 1.48,
		'Test::Pod::Coverage'	=> 1.10,
		'Tree'					=> 1.05,
	},
	VERSION_FROM => 'lib/Tree/Persist.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'perl';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		'meta-spec' =>
		{
			version => 2,
		},
		resources =>
		{
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-Persist',
			license    => 'http://dev.perl.org/licenses/',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/Tree-Persist.git',
				web  => 'https://github.com/ronsavage/Tree-Persist',
			},
		},
	};
}

WriteMakefile(%params);
