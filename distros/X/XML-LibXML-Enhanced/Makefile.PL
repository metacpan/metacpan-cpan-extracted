# -*- perl -*-

use ExtUtils::MakeMaker;

WriteMakefile(

    NAME            => 'XML::LibXML::Enhanced',

    VERSION_FROM    => 'lib/XML/LibXML/Enhanced.pm',

    PREREQ_PM => {
	"Class::Singleton" => 0,
	"XML::LibXML" => 0,
	"XML::LibXSLT" => 0,
	"Data::Eacherator" => 0,
    },

);
