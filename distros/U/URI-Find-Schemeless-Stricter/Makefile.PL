use 5.00503;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'          => 'URI::Find::Schemeless::Stricter',
	'AUTHOR'        => 'Tony Bowden <tmtm@cpan.org>',
	'VERSION_FROM'  => 'lib/URI/Find/Schemeless/Stricter.pm',
	'ABSTRACT_FROM' => 'lib/URI/Find/Schemeless/Stricter.pm',
	'PREREQ_PM'     => { 'URI::Find' => 0.13 },
);
