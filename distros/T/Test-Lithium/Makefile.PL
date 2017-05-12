#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

chomp(my $phantom = qx(phantomjs -v 2>/dev/null));
die "Could not find phantomjs (required for this module)\n" if !$phantom;
die "phantomjs <=1.9.1 is not supported\n" if $phantom eq "1.9.1";

WriteMakefile(
	NAME                => 'Test::Lithium',
	AUTHOR              => "Dan Molik <dan\@d3fy.net>",
	VERSION_FROM        => 'lib/Test/Lithium.pm',
	ABSTRACT_FROM       => 'lib/Test/Lithium.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
		? ('LICENSE'=> 'perl') : ()),
	PL_FILES            => {},
	PREREQ_PM => {
		'Test::More'         => 0,
		'Test::Builder'      => 0,
		'Time::HiRes'        => 0,
		'YAML::XS'           => 0,
		'Dancer'             => 0,
		'Lithium::WebDriver' => 0,
		'MIME::Base64'       => 0,
		'LWP::UserAgent'     => 0,
		'Data::Dumper'       => 0,
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Test-Lithium-*' },
);
