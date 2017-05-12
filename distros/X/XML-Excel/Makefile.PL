use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'XML::Excel',
    'VERSION_FROM' => 'Excel.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other',
    'PREREQ_PM' => { Spreadsheet::ParseExcel => 0.20 }, 
);
