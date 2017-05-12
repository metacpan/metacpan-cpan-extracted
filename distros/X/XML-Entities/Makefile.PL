use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::Entities',
    AUTHOR              => 'Jan Oldřich Krůza <sixtease@cpan.org>',
    VERSION_FROM        => 'lib/XML/Entities.pm',
    ABSTRACT_FROM       => 'lib/XML/Entities.pm',
    LICENSE             => 'perl',
    PM                  => {
        'lib/XML/Entities.pm'       => '$(INST_LIBDIR)/Entities.pm',
        'lib/XML/Entities/Data.pm'  => '$(INST_LIBDIR)/Entities/Data.pm',
        'lib/XML/Entities/Data.pod' => '$(INST_LIBDIR)/Entities/Data.pod',
    },
    PL_FILES            => { },
    EXE_FILES           => [ 'bin/download-entities.pl' ],
    MAN3PODS            => {
        'lib/XML/Entities.pm'       => '$(INST_MAN3DIR)/XML::Entities.3pm',
        'lib/XML/Entities/Data.pod' => '$(INST_MAN3DIR)/XML::Entities::Data.3pm',
        'bin/download-entities.pl'  => '$(INST_MAN3DIR)/download-entities.pl.3pm',
    },
    PREREQ_PM           => {
        'Carp'           => 0,
    },
    BUILD_REQUIRES      => {
        'Test::More'     => 0,
    },
    MIN_PERL_VERSION    => '5.008',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-Entities-*' },
);
