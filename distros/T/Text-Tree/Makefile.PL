use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Text::Tree',
    VERSION_FROM      => 'lib/Text/Tree.pm', # finds $VERSION
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Text/Tree.pm', # retrieve abstract from module
       AUTHOR         => 'Ed Halley <ed@halley.cc>') : ()),
);
