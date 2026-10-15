use ExtUtils::MakeMaker;

WriteMakefile(
    NAME			=> 'ZX81::Tokenize',
    AUTHOR			=> 'Paulo Custodio <pauloscustodio@gmail.com>',
    VERSION_FROM	=> 'lib/ZX81/Tokenize.pm',
    ABSTRACT_FROM	=> 'lib/ZX81/Tokenize.pm',
	LICENSE 		=> 'perl_5',
    PREREQ_PM		=> {
		'Modern::Perl'			=> 1.20250607,
		'Test::More'			=> 1.302225,
		'Test::HexDifferences'	=> 1.001,
    },
);
