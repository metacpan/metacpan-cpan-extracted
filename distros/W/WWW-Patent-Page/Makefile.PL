use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'WWW::Patent::Page',
	AUTHOR        => 'Wanda B. Anon <Wanda.B.Anon@gmail.com>',
	VERSION_FROM  => 'lib/WWW/Patent/Page.pm',
	ABSTRACT_FROM => 'lib/WWW/Patent/Page.pm',
	PL_FILES      => {},
	PREREQ_PM     => {
		'Archive::Zip'          => 0,
		'Carp'                  => 0,
		'Data::Dumper'          => 0,
		'English'               => 0,
		'File::Temp'            => 0.17,
		'File::Spec'            => 0,
		'HTML::Form'            => 0,
		'HTML::HeadParser'      => 0,
		'HTML::TokeParser'      => 0,
		'HTTP::Headers'         => 0,
		'HTTP::Request::Common' => 0,
		'HTTP::Response'        => 0,
		'IO::Scalar'            => 0,
		'LWP::UserAgent'        => 0,
		'PDF::API2'             => 0.53,
		'Test::More'            => 0,
		'URI'                   => 0,
		'base'                  => 0,
		'diagnostics'           => 0,
		'strict'                => 0,
		'subs'                  => 0,
		'vars'                  => 0,
		'version'               => 0,
		'warnings'              => 0,
	},    
	dist => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},

	#   clean               => { FILES => 'WWW-Patent-Page-*' },
);
