use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Correios::SRO',
    AUTHOR              => q{Breno G. de Oliveira <garu@cpan.org>},
    VERSION_FROM        => 'lib/WWW/Correios/SRO.pm',
    ABSTRACT_FROM       => 'lib/WWW/Correios/SRO.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0.88,
        'parent'            => 0,
        'Exporter'          => 0,
        'LWP::UserAgent'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Correios-SRO-*' },
);
