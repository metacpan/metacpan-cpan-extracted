use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'base::Glob',
    'VERSION_FROM'	=> 'Glob.pm', # finds $VERSION
    'PREREQ_PM'		=> {Text::Glob=>0, Sub::Uplevel=>0, Devel::Symdump=>0},
    'ABSTRACT_FROM' => 'Glob.pm', # retrieve abstract from module
    'AUTHOR'        => 'Chris Ball <chris@cpan.org>'
);
