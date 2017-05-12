use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WWW::Translate::interNOSTRUM',
    VERSION_FROM      => 'lib/WWW/Translate/interNOSTRUM.pm', # finds $VERSION
    PREREQ_PM         => {
                          'WWW::Mechanize' => 1.20,
                         },
    LICENSE           => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Translate/interNOSTRUM.pm', # retrieve abstract from module
       AUTHOR         => 'Enrique Nell <blas.gordon@gmail.com>') : ()),
);
