#use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Mechanize::Frames',
    VERSION_FROM      => 'lib/WWW/Mechanize/Frames.pm', # finds $VERSION
    PREREQ_PM         => {
        'Clone::PP' => 0,
        'WWW::Mechanize' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Mechanize/Frames.pm', # retrieve abstract from module
       AUTHOR         => 'Nick Stoianov <cpanperl@yahoo.com>') : ()),
);
