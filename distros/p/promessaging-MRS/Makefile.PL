use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'promessaging::MRS',
    VERSION_FROM      => 'lib/promessaging/MRS.pm', # finds $VERSION
    PREREQ_PM         => {'SOAP::Lite'=>'0','XML::Simple'=>'0'}, # e.g., Module::Name => 1.1
#    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
#      (ABSTRACT_FROM  => 'lib/promessaging/MRS.pm', # retrieve abstract from module
#       AUTHOR         => 'root <root@suse.de>') : ()),
);
