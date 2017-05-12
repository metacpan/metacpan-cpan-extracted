use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'XML::Parser::Lite::Tree',
	'VERSION_FROM'	=> 'lib/XML/Parser/Lite/Tree.pm',
	'PREREQ_PM'	=> {
		'Test::More'		=> 0,
	},
);
