use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Win32::TaskScheduler',
    'VERSION_FROM'	=> 'TaskScheduler.pm', # finds $VERSION
    'PREREQ_PM'		=> {},
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'TaskScheduler.pm', 
       AUTHOR     => 'Umberto Nicoletti <unicolet@netscape.net>') : ()),
    'LIBS'		=> ['-lmstask'], 
    'DEFINE'		=> '-TP', # -TP tells cl to compile all as c++
    'INC'		=> '', # e.g., '-I/usr/include/other'
);
