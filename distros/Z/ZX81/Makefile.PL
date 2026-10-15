use ExtUtils::MakeMaker;

WriteMakefile(
    NAME			=> 'ZX81',
    AUTHOR			=> 'Paulo Custodio <pauloscustodio@gmail.com>',
    VERSION_FROM	=> 'lib/ZX81.pm',
    ABSTRACT_FROM	=> 'lib/ZX81.pm',
	LICENSE 		=> 'perl_5',
    PREREQ_PM		=> {
		'Modern::Perl'			=> 1.20250607,
    },
);
