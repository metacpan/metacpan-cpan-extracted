use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

die "Win32::Process::Memory is only for win32 platform, not for $^O\n"
	if $^O ne "MSWin32";

WriteMakefile(
    NAME              => 'Win32::Process::Memory',
    VERSION_FROM      => 'Memory.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Memory.pm', # retrieve abstract from module
       AUTHOR         => 'Qing-Jie Zhou <qjzhou@hotmail.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);