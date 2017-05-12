use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Twittervision',
    VERSION_FROM      => 'lib/WWW/Twittervision.pm', # finds $VERSION
    PREREQ_PM         => {
                            URI => 1.35,
                            LWP => 5.805,
                            JSON => 2.07
                          },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Twittervision.pm', # retrieve abstract from module
       AUTHOR         => 'Per Henrik Johansen <per.henrik.johansen@gmail.com>') : ()),
);
