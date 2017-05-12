use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::HTPL',
    'VERSION_FROM' => 'HTPL.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
#    'INC'	=> '',     # e.g., '-I/usr/include/other' 
#    'OBJECT'    => '-D__DEBUG__ ../htpl.c ../htpl-l.c ../htpl-sub.c ../htpl-parse.c HTPL.o',
);
