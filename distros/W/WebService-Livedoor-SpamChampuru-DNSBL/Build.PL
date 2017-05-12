use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WebService::Livedoor::SpamChampuru::DNSBL',
    license             => 'perl',
    dist_author         => 'Kensuke Kaneko <k-kaneko@livedoor.jp>',
    dist_version_from   => 'lib/WebService/Livedoor/SpamChampuru/DNSBL.pm',
    build_requires => {
        'Test::More' => 0,
        'Net::DNS' => 0,
        'IO::Select' => 0,
    },
    add_to_cleanup      => [ 'WebService-Livedoor-SpamChampuru-DNSBL-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
