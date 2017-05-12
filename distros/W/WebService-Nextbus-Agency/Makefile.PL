use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WebService::Nextbus::Agency',
    'VERSION_FROM'	=> 'Agency.pm', # finds $VERSION
    'PREREQ_PM'		=> {Test::More, Storable},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Agency.pm', # retrieve abstract from module
       AUTHOR     => 'Peter H. Li <phli@cpan.org>') : ()),
);
