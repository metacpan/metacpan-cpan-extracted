use 5.004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tie::Handle::HTTP',
    VERSION_FROM      => 'lib/Tie/Handle/HTTP.pm', # finds $VERSION
    PREREQ_PM         => {
        LWP::UserAgent  => 0,
        HTTP::Request   => 0,
        HTTP::Status    => 0,
        HTTP::Daemon    => 0,
        HTTP::Response  => 0,
        Errno           => 0,
        Symbol          => 0,
        Test::More      => 0,
        
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/Handle/HTTP.pm', # retrieve abstract from module
       AUTHOR         => 'LiveJournal user <lj@>') : ()),
);
