use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ios_get_interfaces',
    VERSION_FROM      => 'lib/ios_get_interfaces.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'Test'        =>  0, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => 'Get interfaces info from cisco ios configuration file',
       AUTHOR         => 'Cladi Di Domenico <cladi@cpan.org>') : ()),
);
