use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'XSLT::Cache',
	'VERSION_FROM' => 'lib/XSLT/Cache.pm',
	($] >= 5.005 ?
		(
			ABSTRACT_FROM => 'lib/XSLT/Cache.pm',
			AUTHOR => 'Andrew Shitov <andy@shitov.ru>'
		)
		:
		()
	),
    'PREREQ_PM' => {
        'XML::LibXML' => 0,
        'XML::LibXSLT' => 0,
        'File::Cache::Persistent' => 0.3,
    }	
);
