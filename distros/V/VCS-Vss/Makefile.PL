use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'VCS::Vss',
    'VERSION_FROM'	=> 'Vss.pm', 
    'PREREQ_PM'		=> {'VCS'=>0, 'Win32::OLE'=>0}, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'Vss.pm', 
       AUTHOR     => 'James Tillman <jtillman@bigfoot.com>') : ()),
);
