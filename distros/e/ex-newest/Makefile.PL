use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'ex::newest',
    'VERSION_FROM'	=> 'lib/ex/newest.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Test::Simple' => 0.19 },
);
