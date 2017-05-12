use strict;
use warnings;

use ExtUtils::MakeMaker;

# ----------------

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Stevan Little <stevan@cpan.org>',
		ABSTRACT => 'A factory object for dispensing Visitor objects',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile Tree-Simple-VisitorFactory-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Tree-Simple-VisitorFactory',
	NAME         => 'Tree::Simple::VisitorFactory',
	PL_FILES  => {},
	PREREQ_PM    =>
	{
		'base'					=> 0,
		'File::Spec'			=> 0.60,
		'Scalar::Util'			=> 1.10,
		'Tree::Simple'			=> 1.12,
		'Tree::Simple::Visitor'	=> 1.22,
		'strict'				=> 0,
		'warnings'				=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::Exception'	=> '0.15',
		'Test::More'		=> 1.001014,
	},
	VERSION_FROM => 'lib/Tree/Simple/VisitorFactory.pm',
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
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-Simple-VisitorFactorye',
			license    => 'http://dev.perl.org/licenses/',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/Tree-Simple-VisitorFactory.git',
				web  => 'https://github.com/ronsavage/Tree-Simple-VisitorFactory',
			},
		},
	};
}

WriteMakefile(%params);
