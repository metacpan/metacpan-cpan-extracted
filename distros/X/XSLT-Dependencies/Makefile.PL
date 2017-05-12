use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'XSLT::Dependencies',
	'VERSION_FROM' => 'lib/XSLT/Dependencies.pm',
	($] >= 5.005 ?
		(
			ABSTRACT_FROM => 'lib/XSLT/Dependencies.pm',
			AUTHOR => 'Andrew Shitov <andy@shitov.ru>'
		)
		:
		()
	),
    'PREREQ_PM' => {
        'XML::LibXML' => 0,
        'File::Spec' => 0,
        'Cwd' => 0,
    }
);
