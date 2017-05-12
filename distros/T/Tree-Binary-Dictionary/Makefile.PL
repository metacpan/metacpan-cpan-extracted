use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tree::Binary::Dictionary',
    VERSION_FROM      => 'lib/Tree/Binary/Dictionary.pm', # finds $VERSION
    PREREQ_PM         => { Tree::Binary => 0.07 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      ( AUTHOR         => 'aaron trevena <aaron.trevena@gmail.com>') : ()),
);
