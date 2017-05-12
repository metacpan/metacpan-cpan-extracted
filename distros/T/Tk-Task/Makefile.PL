use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tk::Task',
    'VERSION_FROM'	=> 'Task.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Tie::StrictHash' => 1.0 },
);
