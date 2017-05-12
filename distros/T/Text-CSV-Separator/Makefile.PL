use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Text::CSV::Separator',
    VERSION_FROM      => 'lib/Text/CSV/Separator.pm',
    PREREQ_PM         => {},
    LICENSE           => 'perl',
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/Text/CSV/Separator.pm', 
       AUTHOR         => 'Enrique Nell <perl_nell@telefonica.net>') : ()),
);
