use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Tie::Hash::Sorted',
    'VERSION_FROM' => 'Sorted.pm',
    'PREREQ_PM'    => {
        Carp       => 0,
        strict     => 0,
        vars       => 0,
        UNIVERSAL  => 0
    }
);