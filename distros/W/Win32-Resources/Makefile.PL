use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Win32::Resources',
    VERSION_FROM      => 'lib/Win32/Resources.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Win32/Resources.pm',
       AUTHOR         => 'Fabien POTENCIER <fabpot@cpan.org>') : ()),
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
    EXE_FILES         => ['script/add_xpmanifest.pl'],
);
