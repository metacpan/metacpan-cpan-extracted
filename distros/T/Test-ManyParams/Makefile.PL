use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Test::ManyParams',
    'VERSION_FROM'	=> 'ManyParams.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Test::Builder       => 0,
        Set::CrossProduct   => 0,
        Data::Dumper        => 0,

        Test::More          => 0,   # only for the tests
        Test::Exception     => 0,
        Test::Builder::Tester => 0,
        Test::Differences   => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Janek Schleicher <bigj@kamelfreund.de>') : ()),
);
