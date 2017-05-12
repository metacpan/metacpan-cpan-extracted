use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Test::U32',
    VERSION_FROM      => 'lib/Test/U32.pm',
    LICENSE           => 'artistic_2',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Test/U32.pm',
       AUTHOR         => 'Dr James Freeman>') : ()),
);
