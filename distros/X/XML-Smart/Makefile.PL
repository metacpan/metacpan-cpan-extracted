use 5.006                   ;
use strict                  ;
use warnings FATAL => 'all' ;
use ExtUtils::MakeMaker     ;

WriteMakefile(
    NAME             => 'XML::Smart'       ,
    AUTHOR           => q{Graciliano M. P. <gm AT virtuasites.com.br>} ,
    VERSION_FROM     => 'lib/XML/Smart.pm' ,
    ABSTRACT_FROM    => 'lib/XML/Smart.pm' ,
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006              ,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0    ,
    },
    BUILD_REQUIRES => {
        'Test::More'          => 0    ,
    },
    PREREQ_PM => {
	'Object::MultiType'   => 0.03 ,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Blah-*' },
    LICENSE => 'perl'
);

