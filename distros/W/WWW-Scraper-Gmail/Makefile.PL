use 5.005003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Scraper::Gmail',
    VERSION_FROM      => 'lib/WWW/Scraper/Gmail.pm', # finds $VERSION
    PREREQ_PM         => {Crypt::SSLeay}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Scraper/Gmail.pm', # retrieve abstract from module
       AUTHOR         => 'Erik F. Kastner <kastner@gmail.com>') : ()),
);
