use 5.008006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'WWW::Resource',
    VERSION_FROM      => 'lib/WWW/Resource.pm', # finds $VERSION
    PREREQ_PM         => { 
                           FCGI         => 0.0,
                           HTTP::Status => 0.0,
                           JSON         => 0.0,
                           XML::Dumper  => 0.0,
                           }, 
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/WWW/Resource.pm', 
       AUTHOR         => 'Ira Woodhead <ira at sweetpota dot to>') : ()),
);
