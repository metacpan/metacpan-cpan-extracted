# XML::Code makefile

use ExtUtils::MakeMaker;

WriteMakefile (
	'NAME' => 'XML::Code',
	'VERSION_FROM' => 'lib/XML/Code.pm' ,
   ($] >= 5.005 ?
   	('ABSTRACT_FROM' => 'lib/XML/Code.pm',
        'AUTHOR' => 'Andrew Shitov <andy@shitov.ru>') : ())
);

1;

