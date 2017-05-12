use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Tree::Simple::SAX',
    VERSION_FROM => 'lib/Tree/Simple/SAX.pm', 
    PREREQ_PM    => {
        'Test::More'   => 0.47,
        'Tree::Simple' => 1.14,
        'Scalar::Util' => 1.10,
        'XML::SAX'     => 0.12
    }
);
