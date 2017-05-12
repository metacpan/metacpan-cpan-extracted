use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Bio::mGen',
    'VERSION_FROM'	=> 'mGen.pm', 
    'PREREQ_PM'		=> {}, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'mGen.pm', 
       AUTHOR     => 'cyber_indian <cyber_indian@hotmail.com>') : ()),
    'LIBS'		=> [''], 
    'DEFINE'		=> '', 
    'INC'		=> '', 
);