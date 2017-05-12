use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::DOM::XML_Base',
    VERSION_FROM      => 'lib/XML/DOM/XML_Base.pm', # finds $VERSION
    PREREQ_PM         => {
                           'URI'=>0.0,
                           'XML::DOM'=>0.0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/DOM/XML_Base.pm', # retrieve abstract from module
       AUTHOR         => 'Allen Day <allenday@ucla.edu>') : ()),
);
