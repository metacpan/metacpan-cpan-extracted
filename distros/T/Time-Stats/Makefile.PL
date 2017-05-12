use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Time::Stats',
    VERSION_FROM    => 'lib/Time/Stats.pm',
    PREREQ_PM       => { 'Time::HiRes'  => '0' },
);
