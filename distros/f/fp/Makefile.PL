use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'fp',
    VERSION_FROM => 'lib/fp.pm', 
    PREREQ_PM    => {
        'Test::More' => 0.47,
    }
);
