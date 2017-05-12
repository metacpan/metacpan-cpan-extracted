use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'XML::NewsML',
	'VERSION_FROM' => 'lib/XML/NewsML.pm',
	($] >= 5.005 ?
	(ABSTRACT_FROM => 'lib/XML/NewsML.pm',
	AUTHOR => 'Andrew Shitov <andy@shitov.ru>') : ()),
	'PREREQ_PM' => {
		'XML::LibXML' => 0
	}
);
