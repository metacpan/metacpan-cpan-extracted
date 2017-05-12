
use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

die 'OS unsupported' if $^O ne 'MSWin32';

WriteMakefile(
    NAME              => 'Win32::StreamNames',
    VERSION_FROM      => 'lib/Win32/StreamNames.pm', # finds $VERSION
    PREREQ_PM         => {Win32API::File}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Win32/StreamNames.pm', # retrieve abstract from module
       AUTHOR         => 'Clive Darke <clive.darke@talk21.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
   # Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
