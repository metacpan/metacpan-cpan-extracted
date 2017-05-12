use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Win32::WindowsUpdate',
    VERSION_FROM      => 'lib/Win32/WindowsUpdate.pm',
    PREREQ_PM         => {
      Win32::OLE => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Dusty Wilson <dusty#megagram:com>') : ()),
);
