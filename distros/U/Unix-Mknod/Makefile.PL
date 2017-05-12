use 5.006;
use ExtUtils::MakeMaker;
use Config(%Config);

$defines= '-DHAS_SYSMKDEV'
	if ($Config{osname} eq 'solaris');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Unix::Mknod',
    VERSION_FROM      => 'lib/Unix/Mknod.pm', # finds $VERSION
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Unix/Mknod.pm', # retrieve abstract from module
       AUTHOR         => 'Jim Pirzyk <pirzyk@uiuc.edu>') : ()),
    DEFINE            => $defines
);
