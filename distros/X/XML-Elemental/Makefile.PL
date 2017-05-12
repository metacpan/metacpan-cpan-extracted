use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'XML::Elemental',
    'VERSION_FROM' => 'lib/XML/Elemental.pm',
    'PREREQ_PM'    => {
                    XML::SAX     => 0,
                    Scalar::Util => 0,
                    Test::More   => 0,       # test only
                    Task::Weaken => 1.02,    # install only
    },
);
