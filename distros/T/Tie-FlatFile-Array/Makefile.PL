use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tie::FlatFile::Array',
    VERSION_FROM      => 'lib/Tie/FlatFile/Array.pm', # finds $VERSION
    PREREQ_PM         => {Class::Accessor => 0.19}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/FlatFile/Array.pod', # retrieve abstract from module
       AUTHOR         => 'Mumia Wotse <paduille.4060.mumia.w@earthlink.net>') : ()),
);
