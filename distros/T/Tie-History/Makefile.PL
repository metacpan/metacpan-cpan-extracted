use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Tie::History',
    VERSION_FROM      => 'lib/Tie/History.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Tie/History.pm',
       AUTHOR         => 'Larry Shatzer, Jr. <larrysh@cpan.org>') : ()),
);
