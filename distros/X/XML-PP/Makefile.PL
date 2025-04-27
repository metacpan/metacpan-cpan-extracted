#!/usr/bin/env perl

use warnings;
use strict;

use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME         => 'XML::PP',
	VERSION_FROM => 'lib/XML/PP.pm',
	AUTHOR       => 'Nigel Horne <njh@nigelhorne.com>',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, ((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	dist => $dist,
	PREREQ_PM => {
		'Log::Abstraction' => 0,
		'Params::Get' => 0,
		'Scalar::Util' => 0
	}, TEST_REQUIRES => {
		'Data::Dumper' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0
	}, META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				repository => 'https://github.com/nigelhorne/XML-PP',
				type => 'git',
				url => 'git://github.com/nigelhorne/XML-PP.git',
				web => 'https://github.com/nigelhorne/XML-PP'
			}, bugtracker => {
				mailto => 'bug-XML-PP@rt.cpan.org',
				url => 'https://github.com/nigelhorne/XML-PP/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=XML-PP',
				web => 'https://github.com/nigelhorne/XML-PP/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
