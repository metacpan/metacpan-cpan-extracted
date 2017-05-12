use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Win32::IEAutomation',
    VERSION_FROM      => 'lib/Win32/IEAutomation.pm', # finds $VERSION
    PREREQ_PM         => {'Win32::OLE' => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/Win32/IEAutomation.pm', # retrieve abstract from module
       AUTHOR         => 'Prashant Shewale pvshewale@gmail.com') : ()),
);
