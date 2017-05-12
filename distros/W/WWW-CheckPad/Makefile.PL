use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::CheckPad',
    VERSION_FROM      => 'lib/WWW/CheckPad.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/CheckPad.pm', # retrieve abstract from module
       AUTHOR         => '武重　謙（開発用） <ken_dev@apple.com>') : ()),
);
