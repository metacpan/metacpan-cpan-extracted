use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Compete',
    VERSION_FROM      => 'lib/WWW/Compete.pm', # finds $VERSION
    PREREQ_PM         => { "XML::Simple"    => 0,
                           "LWP::UserAgent" => 0 }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Compete.pm', # retrieve abstract from module
       AUTHOR         => 'Chris Mills <cmills@cpan.org>') : ()),
);
