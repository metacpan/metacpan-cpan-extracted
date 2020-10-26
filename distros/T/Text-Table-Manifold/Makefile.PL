use strict;
use warnings;

use ExtUtils::MakeMaker;

# -----------------------------------------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR		=> 'Ron Savage (ron@savage.net.au)',
		ABSTRACT	=> 'Render tables in manifold styles',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Text-Table-Manifold-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'Text-Table-Manifold',
	NAME		=> 'Text::Table::Manifold',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'Const::Exporter'				=> 'v0.2.3',
		'HTML::Entities::Interpolate'	=> 1.05,
		'List::AllUtils'				=> 0.08,
		'Module::Runtime'				=> 0.014,
		'Moo'							=> 1.006000,
		'open'							=> 0,
		'Scalar::Util'					=> 1.50,
		'strict'						=> 0,
		'String::TtyLength'				=> 0.02,
		'Types::Standard'				=> 1.000004,
		'utf8'							=> 0,
		'warnings'						=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001002,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/Text/Table/Manifold.pm',
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
			bugtracker	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-Manifold',
			license		=> 'https://perldoc.perl.org/perlartistic.html',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Text-Table-Manifold.git',
				web		=> 'https://github.com/ronsavage/Text-Table-Manifold',
			},
		},
	};
}

WriteMakefile(%params);
