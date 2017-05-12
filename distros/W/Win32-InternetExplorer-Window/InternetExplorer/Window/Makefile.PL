use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Win32::InternetExplorer::Window',
    'VERSION_FROM'	=> 'Window.pm', 
    'PREREQ_PM'		=> { Win32::OLE => 0.1 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ? 
      (ABSTRACT_FROM => 'Window.pm',
       AUTHOR     => 'MZSanford') : ()),
    'LIBS'		=> [''],
    'DEFINE'		=> '', 
    'INC'		=> '', 
);
