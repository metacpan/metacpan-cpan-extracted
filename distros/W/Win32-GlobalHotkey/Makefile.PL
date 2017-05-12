use 5.016001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Win32::GlobalHotkey',
    VERSION_FROM      => 'lib/Win32/GlobalHotkey.pm', # finds $VERSION
    PREREQ_PM         => { 'Thread::Cancel' =>  '0',  'threads' => '0', 'threads::shared' => '0', 'Carp' => '0' }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Win32/GlobalHotkey.pm', # retrieve abstract from module
       AUTHOR         => 'Tarek Unger <tu2@gmx.net>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
