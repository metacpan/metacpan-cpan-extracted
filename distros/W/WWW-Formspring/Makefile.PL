use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Formspring',
    VERSION_FROM      => 'lib/WWW/Formspring.pm', # finds $VERSION
    PREREQ_PM         => { Carp => 0,
                           LWP::UserAgent => 0,
                           Moose => 0,
                           Net::OAuth => 0,
                           URI => 0,
                           XML::Simple => 0, },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Formspring.pm', # retrieve abstract from module
       AUTHOR         => 'William Orr <will@worrbase.com>') : ()),
);
