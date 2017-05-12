use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'install',
    VERSION_FROM      => 'lib/install.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/install.pm', # retrieve abstract from module
       AUTHOR         => 'David Golden <dagolden@cpan.org') : ()),
    ($ExtUtils::MakeMaker::VERSION > 6.30 ?
      (LICENSE => 'perl',
      ) : () ),
);
