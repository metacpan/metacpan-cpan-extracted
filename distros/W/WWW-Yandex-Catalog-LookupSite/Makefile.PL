use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Yandex::Catalog::LookupSite',
    AUTHOR              => q{Irakliy Sunguryan <webmaster@slovnik.org>},
    VERSION_FROM        => 'lib/WWW/Yandex/Catalog/LookupSite.pm',
    ABSTRACT_FROM       => 'lib/WWW/Yandex/Catalog/LookupSite.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    BUILD_REQUIRES => {
        'Test::More'    => 0,
    },
    PREREQ_PM => {
        'LWP::UserAgent' => 0,
        # URI::UTF8::Punycode is an optional module that will be used, if already installed, to convert punycode IDNs to unicode.
        #                     You should install it manually if you need this feature.
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Yandex-Catalog-LookupSite-*' },
);
