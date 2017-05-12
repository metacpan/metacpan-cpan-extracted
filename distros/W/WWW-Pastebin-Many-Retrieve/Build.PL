use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Pastebin::Many::Retrieve',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/WWW/Pastebin/Many/Retrieve.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                                      => 1.04,
        'WWW::Pastebin::NoMorePastingCom::Retrieve' => 0.001,
        'WWW::Pastebin::PastebinCa::Retrieve'       => 0.001,
        'WWW::Pastebin::PastebinCom::Retrieve'      => 0.002,
        'WWW::Pastebin::PastieCabooSe::Retrieve'    => 0.001,
        'WWW::Pastebin::PhpfiCom::Retrieve'         => 0.001,
        'WWW::Pastebin::RafbNet::Retrieve'          => 0.001,
        'WWW::Pastebin::UbuntuNlOrg::Retrieve'      => 0.001,
        'Class::Data::Accessor'                     => 0.04001,
    },
    add_to_cleanup      => [ 'WWW-Pastebin-Many-Retrieve-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
