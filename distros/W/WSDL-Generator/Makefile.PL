use ExtUtils::MakeMaker;


WriteMakefile(
    NAME	  => "WSDL::Generator",
    VERSION_FROM  => 'lib/WSDL/Generator.pm',
    PREREQ_PM     => {
		     Class::Hook          => 0.01,
		     Test::Simple         => 0.01,
		    },
    AUTHOR        => 'Pierre Denis <pdenis@fotango.com>',
    ABSTRACT      => 'Generates wsdl code without hassle',
);

