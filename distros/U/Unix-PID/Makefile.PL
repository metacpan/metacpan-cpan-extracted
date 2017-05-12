use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Unix::PID',
    VERSION_FROM      => 'PID.pm', 
    PREREQ_PM         => { 
                             'Math::Fibonacci::Phi' => 0,
                             'List::Cycle'          => 0,
                             'Time::HiRes'          => 0,
                             'Fcntl'                => 0,
                         },
    ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'PID.pod',
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
