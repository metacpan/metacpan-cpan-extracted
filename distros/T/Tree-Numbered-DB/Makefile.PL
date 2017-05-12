use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Tree::Numbered::DB',
    'VERSION_FROM'	=> 'DB.pm', 
    'PREREQ_PM'		=> {Tree::Numbered => 1.0}, 
    ($] >= 5.005 ?   
      (AUTHOR     => 'Yosef Meller <mellerf@netvision.net.il>') : ()),
);
