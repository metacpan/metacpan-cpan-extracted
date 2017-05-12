use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Orkut::Spider',
    VERSION_FROM      => 'lib/WWW/Orkut/Spider.pm', # finds $VERSION
    PREREQ_PM         => { WWW::Mechanize => 0.70, HTML::Entities => 1.0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Orkut/Spider.pm', # retrieve abstract from module
       AUTHOR         => 'mm <mm-pause@manno.name>') : ()),
);
