use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::CPANRatings::RSS',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/WWW/CPANRatings/RSS.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'XML::Simple'    => 2.18,
        'LWP::UserAgent' => 2.036,
        'Storable' => 2.18,
        'Class::Data::Accessor' => 0.04001,
        perl => 5.008,
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'WWW-CPANRatings-RSS-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
