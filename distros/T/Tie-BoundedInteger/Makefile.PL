use ExtUtils::MakeMaker 6.46;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'          => 'Tie::BoundedInteger',
	'ABSTRACT'      => 'Limit the magnitude of a number in a scalar',
	'VERSION_FROM'  => 'lib/Tie/BoundedInteger.pm',
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',

	'PREREQ_PM'		=> {
		'Test::More'       => '0.95',
		'Carp'             => '0',
		},

	'clean' => { FILES => 'Tie-Cycle-*' },

	'META_MERGE' => {
        'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git@github.com:briandfoy/tie-boundedinteger.git',
				web  => 'https://github.com/briandfoy/tie-boundedinteger',
				},
			},
		},

	);
