use ExtUtils::MakeMaker;

WriteMakefile (
	'NORECURS'  => 1,
	'NO_META'   => 1,
	'NO_MYMETA' => 1,

	'NAME'      => 'Test::Prereq',
	'VERSION'   => '0.05',
	'PREREQ_PM' => {
		'HTTP::Size'      => 0,
		},
	'PM'        => 
		{
		'lib/Prereq.pm' => '$(INST_LIBDIR)/Prereq.pm',
		},

	depend => { Makefile => 't/test_manifest' },
	test   => { TESTS => $tests },
	);

0;
