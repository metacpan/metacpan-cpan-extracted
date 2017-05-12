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
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Render a cladogram using Imager or Image::Magick',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Tree-Cladogram-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Tree-Cladogram',
	NAME      => 'Tree::Cladogram',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'File::Slurper'		=> 0.008,
		'Getopt::Long'		=> 0,
		#'Image::Magick'	=> 6.9.3, # Image::Magick is optional.
		'Imager'			=> 1.004,
		'Imager::Fill'		=> 1.012,
		'Moo'				=> 2.000002,
		'parent'			=> 0,
		'Pod::Usage'		=> 1.67,
		'strict'			=> 0,
		'Tree::DAG_Node'	=> 1.27,
		'Types::Standard'	=> 1.00000,
		'warnings'			=> 0,
	},
	TEST_REQUIRES =>
	{
		'File::Spec'		=> 0,
		'File::Temp'		=> 0,
		'Test::Pod'			=> 1.51,
		'Test::Simple'		=> 1.302052, # For Test::More.
	},
	VERSION_FROM => 'lib/Tree/Cladogram.pm',
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-Cladogram',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Tree-Cladogram.git',
				web		=> 'https://github.com/ronsavage/Tree-Cladogram',
			},
		},
	};
}

WriteMakefile(%params);
