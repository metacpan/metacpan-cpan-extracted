#!/usr/bin/env perl

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
		ABSTRACT => 'Flower Database, Search Engine and Garden Design',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST WWW-Garden-Design-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'WWW-Garden-Design',
	NAME      => 'WWW::Garden::Design',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'base'						=> 0,
		'boolean'					=> 0.46,
		'Config::Tiny'				=> 2.20,
		'Data::Dumper::Concise'		=> 2.022,
		'Date::Simple'				=> 3.03,
		'DBD::SQLite'				=> 1.52,
		'DBI'						=> 1.630,
		'DBIx::Admin::CreateTable'	=> 2.07,
		'DBIx::Simple'				=> 1.35,
		'Encode'					=> 2.55,
		'File::Copy'				=> 0,
		'File::HomeDir'				=> 0,
		'File::Slurper'				=> 0.009,
		'File::Spec'				=> 0,
		'FindBin'					=> 1.49,
		'Getopt::Long'				=> 2.42,
		'Imager'					=> 1.005,
		'Imager::Fill'				=> 1.012,
		'lib'						=> 0,
		'Lingua::EN::Inflect'		=> 1.895,
		'Mojolicious'				=> 7.33,
		'Mojo::Base'				=> 0,
		'Mojo::Collection'			=> 0,
		'Mojo::Log'					=> 0,
		'Mojo::Pg'					=> 4.08,
		'MojoX::Validate::Util'		=> 1.00,
		'Moo'						=> 2.003004,
		'Moo::Role'					=> 2.003004,
		'open'						=> 0,
		'Params::Classify'			=> 0.013,
		'Path::Tiny'				=> 0.044,
		'Pod::Usage'				=> 1.63,
		'Sort::Naturally'			=> 1.03,
		'strict'					=> 0,
		'SVG::Grid'					=> 1.05,
		'Text::CSV'					=> 1.33,
		'Text::CSV::Encoded'		=> 0.22,
		'Text::Xslate'				=> 1.0007,
		'Time::HiRes'				=> 1.9741,
		'Try::Tiny'					=> 0.30,
		'Types::Standard'			=> 0.032,
		'Unicode::Collate'			=> 1.04,
		'URI::Find::Schemeless'		=> 20160806,
		'utf8'						=> 0,
		'warnings'					=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001002,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/WWW/Garden/Design.pm',
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Garden-Design',
			},
			license    => 'http://dev.perl.org/licenses/',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/WWW-Garden-Design.git',
				web  => 'https://github.com/ronsavage/WWW-Garden-Design',
			},
		},
	};
}

WriteMakefile(%params);
