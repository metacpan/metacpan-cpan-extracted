use ExtUtils::MakeMaker;

WriteMakefile (
	NAME		=> 'Text::Tabulate',
	VERSION_FROM	=> 'lib/Text/Tabulate.pm',
	DISTNAME	=> "Text-Tabulate",
	dist		=> {COMPRESS => 'gzip', SUFFIX => 'gz'},
	EXE_FILES	=> [ qw(bin/tabulate) ],
);

