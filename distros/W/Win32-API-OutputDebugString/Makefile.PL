use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Win32::API::OutputDebugString',
    'VERSION_FROM'	=> 'OutputDebugString.pm', # finds $VERSION
    ($] ge '5.005')?
	      (
	       'AUTHOR'            => 'Alessandro Forghieri (alf@orion.it)',
	       'ABSTRACT'          => 'OutputDebugString Win32 API support',
	       ) : (),
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
);
