use strict;
use warnings;

use ExtUtils::MakeMaker;

# ----------------

print "\n";
print "By default, t/test.t will use File::Temp and DBD::SQLite. \n";
print "To over-ride this, set the env vars \$DBI_DSN, \$DBI_USER and \$DBI_PASS. \n";
print "In all cases, t/test.t will use a table called 'menus'. \n";
print "\n";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Persist multiple trees in a single db table, preserving child order',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile Tree-DAG_Node-Persist-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Tree-DAG_Node-Persist',
	NAME      => 'Tree::DAG_Node::Persist',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'DBI'						=> 1.633,
		'DBIx::Admin::CreateTable'	=> 2.10,
		'File::Temp'				=> 0,
		'Getopt::Long'				=> 2.42,
		'Moo'						=> 2.001001,
		'Pod::Usage'				=> 1.65,
		'Scalar::Util'				=> 1.41,
		'strict'					=> 0,
		'Tree::DAG_Node'			=> 1.24,
		'Types::Standard'			=> 1.000005,
		'warnings'					=> 0,
	},
	TEST_REQUIRES =>
	{
		'DBD::SQLite'	=> 1.46,
		'Test::More'	=> 1.001014,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/Tree/DAG_Node/Persist.pm',
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
		resources   =>
		{
			bugtracker =>
			{
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-DAG_Node-Persist',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Tree-DAG_Node-Persist.git',
				web		=> 'https://github.com/ronsavage/Tree-DAG_Node-Persist',
			},
		},
	};
}

WriteMakefile(%params);
