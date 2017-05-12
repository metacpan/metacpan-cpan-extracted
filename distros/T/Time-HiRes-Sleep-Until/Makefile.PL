use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Time::HiRes::Sleep::Until',
    VERSION_FROM  => 'lib/Time/HiRes/Sleep/Until.pm',
    AUTHOR        => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT_FROM => 'lib/Time/HiRes/Sleep/Until.pm',
    LICENSE       => "gplv2",
    PREREQ_PM     => {
                      'Test::Simple'        => 0.44, #tests
                      'Test::Number::Delta' => 0,    #tests
                      'POSIX'               => 0,    #tests fmod
                      'Package::New'        => 0,    #inherit new
                      'Time::HiRes'         => 0,    #import sleep and time
                      'Math::Round'         => 0.05, #nhimult
                     },
);
