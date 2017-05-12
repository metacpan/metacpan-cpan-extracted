use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::GetPageTitle',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/WWW/GetPageTitle.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'LWP::UserAgent'        => 2.036,
        'Class::Data::Accessor' => 0.04001,
        'HTML::Entities'        => 1.35,
        'perl' => '5.006',
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'WWW-GetPageTitle-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
