use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Typist',
    'VERSION_FROM'	=> 'lib/Typist.pm',
    'PREREQ_PM'		=> { 
        Locale::Maketext=>0, 
        File::Spec=>0,
        Class::Accessor::Fast=>0,
        Class::ErrorHandler=>0,
        Tie::IxHash=>0
    }
);
