use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::LibXML::Iterator',
    'VERSION_FROM'	=> 'lib/XML/LibXML/Iterator.pm',
    'PREREQ_PM'		=> {
                        XML::LibXML    => 1.52,
                        XML::NodeFilter => 0 
                       },
);
