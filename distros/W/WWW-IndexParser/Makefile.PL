use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::IndexParser',
    VERSION_FROM      => 'lib/WWW/IndexParser.pm', # finds $VERSION
    PREREQ_PM         => { LWP => 5.6, HTML::Parser => 3.0, Time::Local => 1.0, URI => 1.0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/IndexParser.pm', # retrieve abstract from module
       AUTHOR         => 'James Bromberger <james@rcpt.to>') : ()),
);
