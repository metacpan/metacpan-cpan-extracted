use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'XML::LibXML::Proxy',
    AUTHOR             => q{Stephane Lavergne <https://github.com/vphantom/>},
    VERSION_FROM       => 'lib/XML/LibXML/Proxy.pm',
    ABSTRACT_FROM      => 'lib/XML/LibXML/Proxy.pm',
    LICENSE            => 'mit',
    PL_FILES           => {},
    MIN_PERL_VERSION   => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
		'XML::LibXML'    => '2.0',
		'LWP::UserAgent' => '6.0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'XML-LibXML-Proxy-*' },
);
