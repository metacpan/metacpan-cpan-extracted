use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %hModules = 
(
        LWP           => undef,
        HTTP::Request => undef,
        URI::Escape   => undef,
        Digest::MD5   => undef,
);
$hModules{Win32::Service} = undef 
            if( $^O eq 'MSWin32' || $^O eq 'Windows_NT');
WriteMakefile(
    NAME              => 'Xpriori::XMS',
    VERSION_FROM      => 'lib/Xpriori/XMS/Http.pm', # finds $VERSION
    PREREQ_PM         => \%hModules, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Xpriori/XMS/Http.pm', # retrieve abstract from module
       AUTHOR         => 'KAWAI,Takanori') : ()),
);
