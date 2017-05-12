use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::WhoCallsMe',
    VERSION_FROM      => 'lib/WWW/WhoCallsMe.pm', # finds $VERSION
    PREREQ_PM         => {
                           LWP => 0.1,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/WhoCallsMe.pm', # retrieve abstract from module
       AUTHOR         => 'Dusty Wilson <dusty--at--hey--d0t--nu>') 
: 
()),
);
