use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Tree::Visualize',
    VERSION_FROM => 'lib/Tree/Visualize.pm', 
    PREREQ_PM    => {
        'Test::More'       => 0.47,
        'Test::Exception'  => 0.15,
        'Class::Throwable' => 0.04,
        'Tree::Simple'     => 1.10,
        'Tree::Binary'     => 0.05
    }
);
