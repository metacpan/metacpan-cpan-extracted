use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Test::PDF',
    VERSION_FROM => 'lib/Test/PDF.pm', 
    PREREQ_PM    => {
    'Test::Builder'         => 0,
    'Test::Deep'            => 0,    
    'CAM::PDF'              => 0,
    'Scalar::Util'          => 0,
    # for testing the module
    'Test::Builder::Tester' => 0,                
    'Test::More'            => 0.47,        
    'File::Spec'            => 0,
    }
);
