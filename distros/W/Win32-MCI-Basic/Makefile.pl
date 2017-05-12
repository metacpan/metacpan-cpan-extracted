use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'AUTHOR'		=> 'Nilson S. F. Junior',
	'ABSTRACT'		=> 'Basic Perl interface to Windows MCI API',
    'NAME'			=> 'Win32::MCI::Basic',
    'VERSION_FROM'	=> 'Basic.pm', # finds $VERSION
    'PREREQ_PM'		=> {Win32::API => 0.01}, # e.g., Module::Name => 1.1
);
