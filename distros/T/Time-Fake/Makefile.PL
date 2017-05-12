use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Time::Fake',
    VERSION_FROM  => 'lib/Time/Fake.pm',
    PREREQ_PM     => { 
                       Carp => 0,
                     },
    ABSTRACT_FROM => 'lib/Time/Fake.pm',
    AUTHOR        => 'Mike Rosulek <mike@mikero.com>',
);
