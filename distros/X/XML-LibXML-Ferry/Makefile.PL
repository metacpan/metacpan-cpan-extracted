use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'XML::LibXML::Ferry',
    AUTHOR           => q{Stephane Lavergne <https://github.com/vphantom/>},
    VERSION_FROM     => 'lib/XML/LibXML/Ferry.pm',
    ABSTRACT_FROM    => 'lib/XML/LibXML/Ferry.pm',
    LICENSE          => 'mit',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
		  'Test::Deep' => '0',
    },
    PREREQ_PM => {
		 'XML::LibXML' => '2.0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'XML-LibXML-Ferry-*' },
);
