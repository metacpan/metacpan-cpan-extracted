use 5.008008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my %options = (
    NAME          => 'WWW::Correios::PrecoPrazo',
    AUTHOR        => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM  => 'lib/WWW/Correios/PrecoPrazo.pm',
    ABSTRACT_FROM => 'lib/WWW/Correios/PrecoPrazo.pm',
    LICENSE       => 'perl',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'     => 0.88,
        'LWP::UserAgent' => 0,
        'Const::Fast'    => 0.012,
        'URI'            => 0,
        'URI::Escape'    => 0,
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            repository => 'https://github.com/garu/WWW-Correios-PrecoPrazo.git',
            bugtracker => 'https://github.com/garu/WWW-Correios-PrecoPrazo/issues',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'WWW-Correios-PrecoPrazo-*' },
);

WriteMakefile(%options);
