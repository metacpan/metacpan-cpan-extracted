use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Workflow::XPDL',
    VERSION_FROM      => 'lib/Workflow/XPDL.pm', # finds $VERSION
    PREREQ_PM         => {'XML::XPath' => '0', 'Carp' => '0', 'Data::Dumper' => '0'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Workflow/XPDL.pm', # retrieve abstract from module
       AUTHOR         => 'Stephen Rhoton <srhoton@cmu.edu>') : ()),
);
