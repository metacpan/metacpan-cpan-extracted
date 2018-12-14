use 5.008001;
use strict;
use warnings;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Yandex::Disk',
    LICENSE           => 'perl_5',
    AUTHOR            => 'Pavel Andryushin',
    VERSION_FROM      => 'lib/Yandex/Disk.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'URI::Escape'           => 3.31,
        'LWP::UserAgent'        => 6.27,
        'LWP::Protocol::https'  => 6.07,
        'JSON::XS'              => 3.04,
        'File::Basename'        => 2.85,
        'Encode'                => 2.60,
        'IO::Socket::SSL'       => 2.002,
        'File::Path::Tiny'      => 0.8,
        'Digest::MD5'           => 2.53,
        'File::Spec'            => 3.4801,
        'Term::Sk'              => 0.18,
    },
    META_MERGE   => {
          requires  => { perl => '5.008008' },
          resources => {
                license     => 'http://dev.perl.org/licenses/',
                repository  => 'https://github.com/vrag86/perl-yandex-disk-api',
                bugtracker  => 'https://github.com/vrag86/perl-yandex-disk-api/issues'
              },
        },
#    ABSTRACT_FROM     => 'lib/Yandex/Disk.pm', # retrieve abstract from module
    AUTHOR            => 'vrag <vrag867@gmail.com>',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
