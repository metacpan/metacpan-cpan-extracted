use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'XMLRPC::Lite::UpdatePing',
    VERSION_FROM      => 'lib/XMLRPC/Lite/UpdatePing.pm',
    LICENSE           => 'perl',
    PREREQ_PM         => { 
                             'Encode'       => 0, 
                             'XMLRPC::Lite' => 0, 
                         },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/XMLRPC/Lite/UpdatePing.pm',
       AUTHOR         => 'Kazuhiro Sera <webmaster@seratch.ath.cx>') : ()),
);
