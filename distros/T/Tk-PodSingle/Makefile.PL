use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::PodSingle',
    VERSION_FROM      => 'lib/Tk/PodSingle.pm', # finds $VERSION
    PREREQ_PM         => {'Tk::Pod' => 0.9929}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tk/PodSingle.pm', # retrieve abstract from module
       AUTHOR         => 'Ken Prows <perl@xev.net>') : ()),
);
