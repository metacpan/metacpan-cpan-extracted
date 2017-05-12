use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'XML::Parser::Lite::Tree::XPath',
	'VERSION_FROM'	=> 'lib/XML/Parser/Lite/Tree/XPath.pm',
	'PREREQ_PM'	=> {
		Test::More		=> 0,
		XML::Parser::Lite::Tree	=> 0.11, # version with namespace/dtd/pi support, callback fix & 5.8.9 fix
	},
);
