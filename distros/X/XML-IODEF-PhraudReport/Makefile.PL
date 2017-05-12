use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::IODEF::PhraudReport',
    VERSION_FROM      => 'lib/XML/IODEF/PhraudReport.pm', # finds $VERSION
    PREREQ_PM         => {XML::IODEF => undef}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/IODEF/PhraudReport.pm', # retrieve abstract from module
       AUTHOR         => 'wes <saxjazman@cpan.org>') : ()),
);
