use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Test::Tiny',
    VERSION_FROM      => 'Tiny.pm',
    PREREQ_PM         => { },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => q|Sean O'Rourke |) : ()),
    ABSTRACT          => 'Simple testing, simply.',
);
