require 5.008;
use ExtUtils::MakeMaker;

die "Win32::MBCS is only for win32 platform, not for $^O\n"
	if $^O ne "MSWin32";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Win32::MBCS',
    VERSION_FROM      => 'MBCS.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'MBCS.pm', # retrieve abstract from module
       AUTHOR         => 'Qing-Jie Zhou <qjzhou@hotmail.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    NO_META           => 1,
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
