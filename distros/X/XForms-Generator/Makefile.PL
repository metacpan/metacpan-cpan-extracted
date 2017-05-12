use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'			=> 'XML::XForms::Generator',
    'AUTHOR'     	=> 'D. Hageman <dhageman@dracken.com>',
    'ABSTRACT' 		=> 'Library for generating W3\'s XForms document elements.',
    'VERSION_FROM'	=> 'Generator.pm',
    'PREREQ_PM'		=> { 'XML::LibXML'			=>	'1.58',
						 'Exporter::Cluster'	=>	0		} 
);
