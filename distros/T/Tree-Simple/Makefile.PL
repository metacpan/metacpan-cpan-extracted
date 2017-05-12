use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

# ----------------

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Stevan Little <stevan@cpan.org>',
		ABSTRACT => 'A simple tree object',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile Tree-Simple-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Tree-Simple',
	NAME      => 'Tree::Simple',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'constant'		=> 0,
		'Scalar::Util'	=> '1.18',
		'strict'		=> 0,
		'warnings'		=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::Exception'	=> '0.15',
		'Test::More'		=> 1.001002,
	},
	VERSION_FROM => 'lib/Tree/Simple.pm',
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
			bugtracker =>
			{
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-Simple',
			},
			license    => 'http://dev.perl.org/licenses/',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/Tree-Simple.git',
				web  => 'https://github.com/ronsavage/Tree-Simple',
			},
		},
	};
}

WriteMakefile(%params);
