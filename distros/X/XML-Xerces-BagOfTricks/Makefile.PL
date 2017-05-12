use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::Xerces::BagOfTricks',
    VERSION_FROM      => 'lib/XML/Xerces/BagOfTricks.pm', # finds $VERSION
    PREREQ_PM         => { XML::Xerces => 2.3 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      ( AUTHOR         => 'Aaron Trevena <aaron@surreytech.co.uk>') : ()),
);
