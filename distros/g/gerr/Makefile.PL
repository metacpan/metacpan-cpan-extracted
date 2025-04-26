use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'gerr',
    VERSION_FROM => 'lib/gerr.pm',  # Path to your main module
    PREREQ_PM    => {},         # Any prerequisites (modules required)
    EXE_FILES    => [],         # Additional executable scripts
    LICENSE      => 'perl',     # License type
);
