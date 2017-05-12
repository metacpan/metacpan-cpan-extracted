use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Pastebin::Bot::Pastebot::Create',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/WWW/Pastebin/Bot/Pastebot/Create.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                  => 1.04,
        'URI'                   => 1.35,
        'LWP::UserAgent'        => 2.036,
        'Devel::TakeHashArgs'   => 0.003,
        'Class::Data::Accessor' => 0.04001,
        'perl' => '5.006',
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'WWW-Pastebin-Bot-Pastebot-Create-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
