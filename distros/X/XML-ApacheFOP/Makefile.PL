use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::ApacheFOP',
    VERSION_FROM      => 'lib/XML/ApacheFOP.pm', # finds $VERSION
    PREREQ_PM         => {'Java'=>4.7}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/ApacheFOP.pm', # retrieve abstract from module
       AUTHOR         => 'Ken Prows <perl@xev.net>') : ()),
);
