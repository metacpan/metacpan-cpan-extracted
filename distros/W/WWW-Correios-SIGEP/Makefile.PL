use strict;
use warnings;
use ExtUtils::MakeMaker;

use File::ShareDir::Install;
install_share 'share';

WriteMakefile(
    NAME          => 'WWW::Correios::SIGEP',
    AUTHOR        => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM  => 'lib/WWW/Correios/SIGEP.pm',
    ABSTRACT_FROM => 'lib/WWW/Correios/SIGEP.pm',
    LICENSE       => 'perl',
    PL_FILES      => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'File::ShareDir::Install' => '0.11',
    },
    PREREQ_PM     => {
        'Test::More'              => '0.88',
        'XML::Compile::WSDL11'    => '3.05',
        'XML::Compile::SOAP'      => '3.20',
        'LWP::UserAgent'          => '0',
        'File::ShareDir::Install' => '0.11',
        'File::ShareDir'          => '1.102',
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/garu/WWW-Correios-SIGEP/issues/',
            repository  => 'https://github.com/garu/WWW-Correios-SIGEP',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Correios-SIGEP-*' },
);

{
    package MY;
    use File::ShareDir::Install qw(postamble);
}
