use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'Test::Subunit',
    'VERSION' => '0.2',
    'test' => { 'TESTS' => 'tests/*.pl' },
    'PMLIBDIRS' => [ 'lib' ],
    'EXE_FILES' => [ 'subunit-diff', 'prove-subunit' ],
    'PREREQ_PM' => {
        'String::CRC32' => 0,
    },
);
