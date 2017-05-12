use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::Malware',
    VERSION_FROM      => 'lib/XML/Malware.pm', # finds $VERSION
    PREREQ_PM         => {XML::Compile => 1.15, XML::LibXML => 1.70}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/Malware.pm', # retrieve abstract from module
       AUTHOR         => 'Wes Young <wes@barely3am.com>') : ()),
);
