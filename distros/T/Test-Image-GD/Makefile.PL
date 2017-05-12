use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Test::Image::GD',
    VERSION_FROM => 'lib/Test/Image/GD.pm', 
    PREREQ_PM    => {
        # for the module itself
        'Test::Builder'         => 0,        
        'GD'                    => 0,
        'Scalar::Util'          => 0,
        # for testing the module
        'Test::Builder::Tester' => 0,                
        'Test::More'            => 0.47,        
        'File::Spec'            => 0,
    }
);
