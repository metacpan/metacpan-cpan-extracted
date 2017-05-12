use ExtUtils::MakeMaker;
$Verbose = 1;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XSTEST::XS1',
    'VERSION_FROM' => 'XS1.pm',
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'XSPROTOARG'	=> '-noprototypes',
    'TYPEMAPS'	=> ['../perlobject.map'],
    'depend'	=> {'XS1.c' => 'Inc1.xsh Inc2.xsh Inc3.xsh Inc4.xsh Inc5.xsh Inc6.xsh Inc7.xsh'},
);
