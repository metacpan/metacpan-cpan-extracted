use ExtUtils::MakeMaker 6.48;
use strict;
use warnings;

require 5.006;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'Test::Manifest',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	'ABSTRACT'     => 'Interact with a t/test_manifest file',
	'VERSION_FROM' => "lib/Test/Manifest.pm",
	'LICENSE'      => 'perl',

	'PREREQ_PM'    => {
		'Test::More'         => '0.95',
		},

	MIN_PERL_VERSION => 5.006,

	META_MERGE => {
			resources => {
				bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Manifest',
		  		repository => 'git://github.com/briandfoy/test-manifest.git',
				},
			keywords => [ 'module', 'distribution', 'test' ],
	  		},

	clean => { FILES => '*.bak release-* Test-*' },
	);
