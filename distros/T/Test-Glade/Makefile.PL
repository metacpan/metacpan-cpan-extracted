use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Test::Glade',
    VERSION_FROM      => 'lib/Test/Glade.pm',
    PREREQ_PM         => {'Test::Builder' => 0, 'XML::Parser' => 0},
    ($] >= 5.005 ?
       (AUTHOR         => 'Nate Mueller <nate@cs.wisc.edu>') : ()),
);
