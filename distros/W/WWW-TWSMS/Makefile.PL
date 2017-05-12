use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::TWSMS',
    DISTNAME          => 'WWW-TWSMS',
    VERSION_FROM      => 'lib/WWW/TWSMS.pm', # finds $VERSION
    PREREQ_PM         => {
            HTTP::Request::Common       => 1.26,
            HTTP::Cookies               => 1.39,
            LWP::UserAgent              => 2.033,

    },
    ($] >= 5.006 ?     ## Add these new keywords supported since 5.006
      (ABSTRACT_FROM  => 'lib/WWW/TWSMS.pm', # retrieve abstract from module
       AUTHOR         => 'Tsung-Han Yeh <snowfly@yuntech.edu.tw>') : ()),
);
