use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'			=> 'Time::Epoch',
	'VERSION_FROM'		=> 'Epoch.pm',
	'PREREQ_PM'		=> {
		'Test::More'	=> 0,
	},
	'clean'			=> {
		'FILES'	=> 'Time-Epoch-*'
	},
);
