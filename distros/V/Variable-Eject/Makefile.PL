use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Variable::Eject',
	VERSION_FROM      => 'lib/Variable/Eject.pm',
	ABSTRACT_FROM     => 'lib/Variable/Eject.pm',
	PREREQ_PM         => {
		'uni::perl'      => 0.03,
		'Devel::Declare' => '0.005011',
		'Lexical::Alias' => '0.04'
	},
	TEST_REQUIRES => {
		'lib::abs'         => 0.90,
		'Test::If'         => 0,
		'Test::More'       => 0,
		'Test::NoWarnings' => 0,
	},
	AUTHOR            => 'Mons Anderson <mons@cpan.org>',
	LICENSE           => 'perl',
);
