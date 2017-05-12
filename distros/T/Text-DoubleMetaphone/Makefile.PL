use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Text::DoubleMetaphone',
    'VERSION_FROM' => 'DoubleMetaphone.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '-DMETA_USE_PERL_MALLOC', # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'OBJECT'    => 'double_metaphone.o DoubleMetaphone.o',
    'dist'      => {
        COMPRESS => 'gzip', SUFFIX => 'gz',
    },        
);
