use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'          =>  'Tie::MLDBM',
    'PREREQ_PM'         =>  {
        'Tie::DBI'          =>  0.91
    },
    'VERSION_FROM'  =>  'lib/Tie/MLDBM.pm'
);
