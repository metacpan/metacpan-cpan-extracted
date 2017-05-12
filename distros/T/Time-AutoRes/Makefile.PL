use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Time::AutoRes',
    'AUTHOR'       => 'Paul Hoffman (nkuitse AT cpan DOT org)',
    'VERSION_FROM' => 'lib/Time/AutoRes.pm',
    'PREREQ_PM'    => {
        'Test::Without::Module' => 0,
    },
);

