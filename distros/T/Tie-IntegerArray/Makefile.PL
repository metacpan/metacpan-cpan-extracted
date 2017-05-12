use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tie::IntegerArray',
    'VERSION_FROM'	=> 'IntegerArray.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Bit::Vector' => 0}, # e.g., Module::Name => 1.1
);
