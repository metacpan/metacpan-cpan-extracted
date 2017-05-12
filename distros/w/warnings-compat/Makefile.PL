use strict;
use ExtUtils::MakeMaker;

warn " -" x 20, $/, 
     "This module is only intended for pre-5.6 Perls. Perl $] already has\n",
     "the real module, so only a stub will be installed by the current distribution.\n",
     " -" x 20, $/
    if $] >= 5.006;

WriteMakefile(
    NAME                => 'warnings',
    DISTNAME            => 'warnings-compat',
    LICENSE             => 'perl',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/warnings.pm',
    ABSTRACT            => 'warnings.pm emulation for pre-5.6 Perls',
    PREREQ_PM => {
        'Test::More' => 0,
    },
    PL_FILES            => {},
    ( $] >= 5.006 ? (PM => {
        "lib/warnings/compat.pm" => '$(INST_LIBDIR)/warnings/compat.pm'
    }) : () ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'warnings-compat-*' },
);
