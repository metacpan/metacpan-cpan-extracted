use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Test::GreaterVersion',
	VERSION_FROM => 'lib/Test/GreaterVersion.pm',
	ABSTRACT     => 'Test if you incremented VERSION',             
	AUTHOR       => 'Gregor Goldbach <glauschwuffel@nomaden.org>',
	PREREQ_PM    => {
		CPAN          => 0,
		CPAN::Version => 0,
		Cwd           => 0,
		File::Spec    => 0,
		Test::Builder => 0
	},
	LICENSE      => 'perl',
	PREREQ_FATAL => 1
);
