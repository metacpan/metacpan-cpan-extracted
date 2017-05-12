use 5.016003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'UserDB',
    VERSION_FROM      => 'lib/UserDB.pm', # finds $VERSION
    PREREQ_PM         => {'DBI' => '1.630', 'Digest::SHA' => '5.85'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/UserDB.pm', # retrieve abstract from module
       AUTHOR         => 'Patrick Lambert <dendory@live.ca>') : ()),
);
