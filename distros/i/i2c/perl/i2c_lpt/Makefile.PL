use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#(LIB_EXT)',

WriteMakefile(
    'NAME'	=> 'i2c_lpt',
    'VERSION_FROM' => 'i2c_lpt.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'MYEXTLIB'  => 'lib/i2c_lpt$(LIB_EXT)',
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
);
                           
use ExtUtils::MakeMaker;
use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
  
