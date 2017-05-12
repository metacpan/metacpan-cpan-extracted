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
		ABSTRACT => 'Render tables in manifold styles',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Text-Table-Manifold-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Text-Table-Manifold',
	NAME      => 'Text::Table::Manifold',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Const::Exporter'             => 'v0.2.3',
		'HTML::Entities::Interpolate' => 1.05,
		'List::AllUtils'              => 0.08,
		'Module::Runtime'             => 0.014,
		'Moo'                         => 1.006000,
		'open'                        => 0,
		'strict'                      => 0,
		'Test::More'                  => 1.001006,
#		'Test::Pod'                   => 1.45, # Make it optional. See xt/author/pod.t
		'Types::Standard'             => 1.000004,
		'Unicode::GCString'           => 2013.10,
		'utf8'                        => 0,
		'warnings'                    => 0,
	},
	VERSION_FROM => 'lib/Text/Table/Manifold.pm',
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
			version => 2,
		},
		resources   =>
		{
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-Manifold',
			license    => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/Text-Table-Manifold.git',
				web  => 'https://github.com/ronsavage/Text-Table-Manifold',
			},
		},
	};
}

WriteMakefile(%params);
