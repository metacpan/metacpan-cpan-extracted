use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME             => 'WebService::Northern911',
    AUTHOR           => q{Mark Wells <mark@freeside.biz>},
    VERSION_FROM     => 'lib/WebService/Northern911.pm',
    ABSTRACT_FROM    => 'lib/WebService/Northern911.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'File::ShareDir::Install' => 0,
    },
    PREREQ_PM => {
        'XML::Compile'        => 1.0,
        'XML::Compile::SOAP'  => 3.0,
        'XML::Compile::WSDL11'=> 3.0,
        'File::ShareDir'      => 0,
        'DateTime'            => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-Northern911-*' },
);

package MY;
use File::ShareDir::Install qw(postamble);

