#!/usr/bin/env perl

use 5.6.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my(%params) =
(
	AUTHOR		=> q{Mario Zieschang <mziescha@cpan.org>},
	ABSTRACT	=> 'A set of classes for viewing Tree::Simple hierarchies',
	clean		=>
	{
		FILES => 'blib/* Makefile MANIFEST Tree-Simple-View-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME			=> 'Tree-Simple-View',
	NAME				=> 'Tree::Simple::View',
	MIN_PERL_VERSION	=> 5.6.0,
	PL_FILES			=> {},
	CONFIGURE_REQUIRES	=>
	{
		'ExtUtils::MakeMaker' => 0,
	},
	PREREQ_PM =>
	{
		'Class::Throwable'	=> 0.10,
		'constant'			=> 0,
		'parent'			=> 0,
		'perl'				=> 5.6.0,
		'Scalar::Util'		=> 1.18,
		'strict'			=> 0,
		'Tree::Simple'		=> 1.31,
		'warnings'			=> 0,
	},
	TEST_REQUIRES => {
		'Test::More'	   => 0.47,
		'Test::Exception'  => 0.15,
		'Test::LongString' => 0,
	},
	VERSION_FROM => 'lib/Tree/Simple/View.pm',
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-Simple-View',
			},
			license    => 'http://dev.perl.org/licenses/',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/rsavage/Tree-Simple-View.git',
				web  => 'https://github.com/mziescha/Tree-Simple-View',
			},
		},
	};
}

WriteMakefile(%params);
