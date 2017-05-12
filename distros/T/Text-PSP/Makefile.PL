use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Text::PSP',
    'VERSION_FROM'	=> 'lib/Text/PSP.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Test::More' => 0}, # e.g., Module::Name => 1.1
    'realclean'		=> {FILES => 'tmp/work, tmp'}
);



