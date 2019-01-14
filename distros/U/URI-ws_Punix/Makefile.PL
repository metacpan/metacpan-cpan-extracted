use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'URI::ws_Punix',
    VERSION_FROM      => 'lib/URI/ws_Punix.pm', # finds $VERSION
    LICENSE=>'perl_5',
    PREREQ_PM         => {
    qw(
      URI::Encode     0
      URI             0
    )
    
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/URI/ws_Punix.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Shipper <AKALINUX@CPAN.ORG>') : ()),
);
