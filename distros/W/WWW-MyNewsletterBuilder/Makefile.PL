use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::MyNewsletterBuilder',
    VERSION_FROM      => 'lib/WWW/MyNewsletterBuilder.pm', # finds $VERSION
    PREREQ_PM         => {Frontier::Client => 0, Data::Dumper => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/MyNewsletterBuilder.pm', # retrieve abstract from module
       AUTHOR         => 'Robert Davis <robert@jbanetwork.com>') : ()),
);
