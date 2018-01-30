use strict;
use warnings;

use 5.008_001; # For the utf-8 stuff.

use ExtUtils::MakeMaker;

# -----------------------------------------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	ABSTRACT	=> 'An N-ary tree',
	AUTHOR		=> 'Sean M. Burke <sburke@cpan.org>',
	clean		=>
	{
		FILES => 'blib/* Makefile MANIFEST Tree-DAG_Node-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'Tree-DAG_Node',
	NAME		=> 'Tree::DAG_Node',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'File::Slurp::Tiny'	=> 0.003,
		'open'				=> 0,
		'strict'			=> 0,
		'utf8'				=> 0,
		'warnings'			=> 0,
	},
	TEST_REQUIRES =>
	{
		'File::Spec'	=> 3.40,
		'File::Temp'	=> 0.19,
		'Test::More'	=> 1.001002,
	},
	VERSION_FROM => 'lib/Tree/DAG_Node.pm',
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
		prereqs =>
		{
			develop =>
			{
				requires =>
				{
					'Test::Pod' => 1.48
				}
			}
		},
		resources =>
		{
			bugtracker	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-DAG_Node',
			license		=> 'http://opensource.org/licenses/Artistic-2.0',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Tree-DAG_Node.git',
				web		=> 'https://github.com/ronsavage/Tree-DAG_Node',
			},
		},
	};
}

WriteMakefile(%params);
