use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WWW::Workflowy',
    VERSION_FROM      => 'lib/WWW/Workflowy.pm',
    PREREQ_PM         => {
        PadWalker => 0.01, 
        LWP       => 0.01,
        autobox   => 0.01,
        'LWP::Protocol::https' => 0.01,
    },
    ABSTRACT_FROM  => 'lib/WWW/Workflowy.pm',
    AUTHOR         => 'Scott Walters <scott@slowass.net>',
);
