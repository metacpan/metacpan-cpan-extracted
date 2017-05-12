use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ebXML::Message',
    VERSION_FROM      => 'lib/ebXML/Message.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ebXML/Message.pm', # retrieve abstract from module
       AUTHOR         => 'aaron trevena <aaron@surreytech.co.uk>') : ()),
);
