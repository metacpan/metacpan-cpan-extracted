use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tie::CSV_File',
    'VERSION_FROM'	=> 'CSV_File.pm', # finds $VERSION
    'LICENSE'	        => 'perl',
    'PREREQ_PM'		=> {
        'Text::CSV_XS'    => 0,
        'Tie::File'       => 0,
        'Params::Validate'=> 0,
        
        'Test::Exception' => 0,    # for the tests
        'Test::More'      => 0,
        'File::Temp'      => 0,
        'Data::Compare'   => 0,
        'Test::Warn'      => 0.05,
        'Test::ManyParams'=> 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Janek Schleicher <bigj@kamelfreund.de>',
       ABSTRACT   => 'ties a csv file to an array of arrays') : ()
    ),
);
