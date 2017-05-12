use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'iodbc',
    'VERSION_FROM' => 'iodbc.pm', # finds $VERSION
    #Please put the iodbc library below
    'LIBS'	=> [''],       	  # e.g., '-liodbc' 
    'DEFINE'	=> '',            # e.g., '-DHAVE_SOMETHING'
    #Please put where the iodbc include directory is located here. 
    'INC'	=> '',            # e.g., '-I/usr/local/iodbc-2.12.0/include' 
);
