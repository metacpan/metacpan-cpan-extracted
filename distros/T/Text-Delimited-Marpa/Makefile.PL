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
		ABSTRACT => 'Extract delimited text sequences from strings',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Text-Delimited-Marpa-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Text-Delimited-Marpa',
	NAME      => 'Text::Delimited::Marpa',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Const::Exporter' => 'v0.2.3',
		'Marpa::R2'       => 2.096000,
		'Moo'             => 1.006000,
		'open'            => 0,
		'strict'          => 0,
		'Test::More'      => 1.001006,
#		'Test::Pod'       => 1.45, # Make it optional. See xt/author/pod.t
		'Tree'            => 1.06,
		'Try::Tiny'       => 0.09,
		'Types::Standard' => 1.000004,
		'utf8'            => 0,
		'warnings'        => 0,
	},
	VERSION_FROM => 'lib/Text/Delimited/Marpa.pm',
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
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Delimited-Marpa',
			license    => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/Text-Delimited-Marpa.git',
				web  => 'https://github.com/ronsavage/Text-Delimited-Marpa',
			},
		},
	};
}

WriteMakefile(%params);
