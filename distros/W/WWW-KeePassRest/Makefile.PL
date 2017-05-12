use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share module => 'WWW::KeePassRest', 'cert';

WriteMakefile(
    NAME             => 'WWW::KeePassRest',
    AUTHOR           => q{Michael Roberts <michael@vivtek.com>},
    VERSION_FROM     => 'lib/WWW/KeePassRest.pm',
    ABSTRACT_FROM    => 'lib/WWW/KeePassRest.pm',
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
        'WWW::JSONAPI' => 0,
        'File::ShareDir' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
               type => 'git',
               url  => 'https://github.com/Vivtek/WWW-KeePassRest.git',
               web  => 'https://github.com/Vivtek/WWW-KeePassRest',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-KeePassRest-*' },
);

package MY;
use File::ShareDir::Install qw( postamble );