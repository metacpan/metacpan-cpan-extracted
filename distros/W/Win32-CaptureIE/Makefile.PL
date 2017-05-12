use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Win32::CaptureIE',
    VERSION_FROM      => 'CaptureIE.pm', # finds $VERSION
    PREREQ_PM         => {
      Image::Magick	=> 0,
      Win32::Screenshot	=> 1.20,
      Win32::OLE	=> 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'CaptureIE.pm', # retrieve abstract from module
       AUTHOR         => 'P.Smejkal <petr.smejkal@seznam.cz>') : ()),
);
