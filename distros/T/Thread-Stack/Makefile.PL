use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Thread::Stack',
    VERSION_FROM      => 'lib/Thread/Stack.pm',
    PREREQ_PM         => { },
    ($] >= 5.005 ?
      (AUTHOR         => 'W. Kyle Schlansker <kylesch@gmail.com>') : ()),
);
