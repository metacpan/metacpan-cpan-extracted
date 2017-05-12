use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WebService::SagawaKyubin',
    license             => 'perl',
    dist_author         => 'OONO Yoshitaka <aab61120@pop12.odn.ne.jp>',
    dist_version_from   => 'lib/WebService/SagawaKyubin.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Encode'             => 0,
        'WWW::Mechanize'     => 1.22,
        'Web::Scraper'       => 0,
        'YAML'               => 0,
    },
    add_to_cleanup      => [ 'WebService-SagawaKyubin-*' ],
);

$builder->create_build_script();
