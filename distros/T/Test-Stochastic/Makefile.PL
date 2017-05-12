use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::Stochastic',
    VERSION_FROM      => 'lib/Test/Stochastic.pm', # finds $VERSION
    PREREQ_PM         => { Scalar::Util =>  1.17}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/Stochastic.pm', # retrieve abstract from module
       AUTHOR         => 'Abhijit Mahabal <amahabal@cs.indiana.edu>') : ()),
);
