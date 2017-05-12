use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WordNet::SenseKey',
    VERSION_FROM      => 'lib/WordNet/SenseKey.pm', # finds $VERSION
    PREREQ_PM         => {WordNet::QueryData => 1.1}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WordNet/SenseKey.pm', # retrieve abstract from module
       AUTHOR         => 'Linas Vepstas <linasvepstas@gmail.com>') : ()),
);
