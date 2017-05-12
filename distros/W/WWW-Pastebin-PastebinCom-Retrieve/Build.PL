use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Pastebin::PastebinCom::Retrieve',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/WWW/Pastebin/PastebinCom/Retrieve.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                          => 1.04,
        'URI'                           => 1.35,
        'HTML::TokeParser::Simple'      => 3.15,
        'HTML::Entities'                => 1.35,
        'WWW::Pastebin::Base::Retrieve' => 0.001,
    },
    add_to_cleanup      => [ 'WWW-Pastebin-PastebinCom-Retrieve-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
