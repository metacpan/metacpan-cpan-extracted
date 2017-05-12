use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WoW::Wiki',
    VERSION_FROM      => 'lib/WoW/Wiki.pm', # finds $VERSION
    PREREQ_PM         => {Storable => 1.0, XML::SimpleObject => 0.5}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WoW/Wiki.pm', # retrieve abstract from module
       AUTHOR         => 'Sal  Scotto <sal.scotto@gmail.com>') : ()),
);
