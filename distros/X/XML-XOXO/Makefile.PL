use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::XOXO',
    'VERSION_FROM'	=> 'lib/XML/XOXO.pm',
    'PREREQ_PM'		=> { XML::Parser=>2, Class::XPath=>1.4 } 
);
