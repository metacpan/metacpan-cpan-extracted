use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::DOM::BagOfTricks',
    VERSION_FROM      => 'lib/XML/DOM/BagOfTricks.pm', # finds $VERSION
    PREREQ_PM         => { XML::DOM => 1.27 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
       (AUTHOR         => 'Aaron Trevena <teejay@droogs.org>') : ()),
);
