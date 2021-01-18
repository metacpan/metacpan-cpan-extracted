use 5.008000;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'Web::Sitemap',
	VERSION_FROM     => 'lib/Web/Sitemap.pm', # finds \$VERSION
	MIN_PERL_VERSION => '5.008000',

	AUTHOR           => 'Mikhail N Bogdanov (bogdanovmn@gmail.com)',
	LICENSE          => 'perl',
	ABSTRACT_FROM    => 'lib/Web/Sitemap.pm',

	TEST_REQUIRES    => {
		'IO::Uncompress::Gunzip' => 0,
	},

	PREREQ_PM        => {
		'IO::Compress::Gzip' => 0,
	},

	META_MERGE => {
		resources   => {
			license    => 'https://dev.perl.org/licenses',
			bugtracker => 'https://github.com/bogdanovmn/perl-web-sitemap/issues',
			repository => 'https://github.com/bogdanovmn/perl-web-sitemap',
		},
	},

);
