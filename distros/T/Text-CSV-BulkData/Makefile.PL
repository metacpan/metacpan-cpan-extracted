use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Text::CSV::BulkData',
    VERSION_FROM      => 'lib/Text/CSV/BulkData.pm',
    LICENSE           => 'perl',
    PREREQ_PM         => {},
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'lib/Text/CSV/BulkData.pm', 
       AUTHOR         => 'Kazuhiro Sera <webmaster@seratch.ath.cx>') : ()),
);

