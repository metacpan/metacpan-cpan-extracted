use strict;
use warnings;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Convert XML::Tiny output into a Tree',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST XML-Tiny-Tree-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'XML-Tiny-Tree',
	NAME      => 'XML::Tiny::Tree',
	LICENSE   => 'artistic_2',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'File::Spec'      => 0,
		'Moo'             => 1.007000,
		'strict'          => 0,
		'Test::More'      => 1.001014,
#		'Test::Pod'       => 1.48, # Make it optional. See xt/author/pod.t
		'Tree'            => 1.07,
		'Types::Standard' => 1.000005,
		'warnings'        => 0,
		'XML::Tiny'       => 2.06,
	},
	VERSION_FROM => 'lib/XML/Tiny/Tree.pm',
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
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=XML-Tiny-Tree',
			license    => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/XML-Tiny-Tree.git',
				web  => 'https://github.com/ronsavage/XML-Tiny-Tree',
			},
		},
	};
}

WriteMakefile(%params);
