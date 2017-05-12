use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WWW::Translate::Apertium',
    VERSION_FROM      => 'lib/WWW/Translate/Apertium.pm', # finds $VERSION
    PREREQ_PM         => {
                          'LWP::UserAgent' => 0,
                          'URI::Escape'    => 1.36,
                          'HTML::Entities' => 3.58,
                         },
    LICENSE           => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Translate/Apertium.pm', # retrieve abstract from module
       AUTHOR         => 'Enrique Nell <perl_nell@telefonica.net>') : ()),
);
