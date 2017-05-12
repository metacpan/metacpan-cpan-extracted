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
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Parse X.500 DNs',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST X500-DN-Marpa-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'X500-DN-Marpa',
	NAME      => 'X500::DN::Marpa',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Const::Exporter' => 'v0.2.3',
		'Marpa::R2' => 2.096000,
		'Moo' => 1.006000,
		'parent' => 0,
		'Set::Array' => 0.30,
		'strict' => 0,
		'Test::More' => 1.001014,
		'Test::Pod' => 1.48,
		'Try::Tiny' => 0.09,
		'Types::Standard' => 1.000004,
		'utf8' => 0,
		'Want' => 0.25,
		'warnings' => 0,
	},
	VERSION_FROM => 'lib/X500/DN/Marpa.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'artistic_2';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		'meta-spec' =>
		{
		'version' => 2,
		},
		resources   =>
		{
		'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=X500-DN-Marpa',
		'license' => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
		'type' => 'git',
		'url' => 'https://github.com/ronsavage/X500-DN-Marpa.git',
		'web' => 'https://github.com/ronsavage/X500-DN-Marpa',
			},
		},
	};
}

WriteMakefile(%params);
