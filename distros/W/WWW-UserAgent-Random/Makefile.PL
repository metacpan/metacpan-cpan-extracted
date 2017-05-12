use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WWW::UserAgent::Random',
    VERSION_FROM      => 'lib/WWW/UserAgent/Random.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WWW/UserAgent/Random.pm',
       AUTHOR         => 'Matteo Cantoni <matteo.cantoni@nothink.org>') : ()),
);
