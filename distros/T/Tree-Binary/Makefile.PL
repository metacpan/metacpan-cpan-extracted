use strict;
use warnings;

use ExtUtils::MakeMaker;

# ----------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Stevan Little (stevan@iinteractive.com)',
		ABSTRACT => 'An Object Oriented Binary Tree for Perl',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Tree-Binary-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Tree-Binary',
	NAME      => 'Tree::Binary',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'constant'		=> 0,
		'Scalar::Util'	=> 1.10,
		'strict'		=> 0,
		'warnings'		=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::Exception'		=> '0.15',
		'Test::More'			=> 1.001014,
		'Test::Pod'				=> 1.48,
		'Test::Pod::Coverage'	=> 1.10,
	},
	VERSION_FROM => 'lib/Tree/Binary.pm',
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
			bugtracker	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-Binary',
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Tree-Binary.git',
				web		=> 'https://github.com/ronsavage/Tree-Binary',
			},
		},
	};
}

WriteMakefile(%params);
