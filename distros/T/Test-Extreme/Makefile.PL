use 5.012004;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Test::Extreme',
    VERSION_FROM      => 'lib/Test/Extreme.pm', # finds $VERSION
    PREREQ_PM         => { 'Carp' => 0, 'Exporter' => 0, },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/Extreme.pm', # retrieve abstract from module
       AUTHOR         => 'Asim Jalis <asimjalis@gmail.com>') : ()),
);
