use ExtUtils::MakeMaker;
WriteMakefile(
	PL_FILES     => {},
	INSTALLDIRS  => 'site',
	NAME         => 'Test::TAP::Model',
	EXE_FILES    => [],
	VERSION_FROM => 'lib/Test/TAP/Model.pm',
	SIGN         => 1,
	PREREQ_PM    => {
		'Test::Harness::Straps' => '0.30',
		'Test::More' => '0.53',
		'Method::Alias' => 0
	},
);
