use ExtUtils::MakeMaker 6.65;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile (
	'NAME'          => 'Test::ISBN',
	'ABSTRACT'      => 'Check International Standard Book Numbers',
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',

	'VERSION_FROM'   => 'lib/Test/ISBN.pm',
	'PREREQ_PM'      => {
		'Business::ISBN'        => '2.0',
		},

	'TEST_REQUIRES' => {
		'Test::More'            => '0',
		'Test::Builder::Tester' => '0',
		},

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
			resources => {
				repository => {
					type => 'git',
					url  => 'https://github.com/briandfoy/Test-ISBN.git',
					web  => 'https://github.com/briandfoy/Test-ISBN',
				},
			},
		},

	clean            => { FILES => 'Test-ISBN-*' },
	);

