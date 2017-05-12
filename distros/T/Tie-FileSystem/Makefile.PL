use 5.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tie::FileSystem',
    VERSION_FROM      => 'lib/Tie/FileSystem.pm', # finds $VERSION
    PREREQ_PM         => { Tie::Hash => 0,
                           Data::Dumper => 0,
                           Symbol => 0,
                           Fcntl => 0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/FileSystem.pm', # retrieve abstract from module
       AUTHOR         => 'Vadim V. Kouevda <initdotd@cpan.org>') : ()),
);
