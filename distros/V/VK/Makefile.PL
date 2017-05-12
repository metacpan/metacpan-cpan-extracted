use 5.012002;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'VK',
    VERSION_FROM      => 'lib/VK.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?  
      (ABSTRACT_FROM  => 'lib/VK.pm', # retrieve abstract from module
       AUTHOR         => 'Marat Shaymardanov <info@leonmedia.ru>') : ()),
);
