use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::phpBB::Mod::Installer',
    VERSION_FROM      => 'lib/WWW/phpBB/Mod/Installer.pm', # finds $VERSION
    PREREQ_PM         => {XML::Xerces => 2.3.0-4,
                          DBI => 1.50,
                          DBD::mysql => 3.0002,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/phpBB/Mod/Installer.pm', # retrieve abstract from module
       AUTHOR         => 'Ian Clark') : ()),
);
