use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'Test::Subunit',
    'VERSION' => '0.1',
    'test' => { 'TESTS' => 'tests/*.pl' },
    'PMLIBDIRS' => [ 'lib' ],
    'EXE_FILES' => [ 'subunit-diff' ],
);
