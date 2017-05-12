use 5.010000;
use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $lavf_lib = ExtUtils::PkgConfig->libs("libavformat");
my $lavf_inc = ExtUtils::PkgConfig->cflags("libavformat");
die("Installed libavformat version is too low. I require 52.7 or greater") unless (
	ExtUtils::PkgConfig->atleast_version("libavformat", "52.7.0"));

WriteMakefile(
    NAME              => 'Video::FFmpeg',
    VERSION_FROM      => 'lib/Video/FFmpeg.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Video/FFmpeg.pm', # retrieve abstract from module
       AUTHOR         => 'Max Vohra <max@seattlenetworks.com>') : ()),
    LIBS              => [$lavf_lib], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. '.$lavf_inc, # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
