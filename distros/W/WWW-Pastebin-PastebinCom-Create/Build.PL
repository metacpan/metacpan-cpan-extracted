use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Pastebin::PastebinCom::Create',
    license             => 'Artistic_2_0',
    dist_author         => q{Zoffix Znet <zoffix@cpan.org>},
    dist_version_from   => 'lib/WWW/Pastebin/PastebinCom/Create.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Moo'            => 1.004001,
        'WWW::Mechanize' => 1.73,
        'overload'       => 0,
        perl             => '5.006',
    },
    add_to_cleanup     => [ 'WWW-Pastebin-PastebinCom-Create-*' ],
    create_makefile_pl => 'traditional',
);
if ( $ENV{RELEASE_TESTING} ) {
    system('pod2text lib/WWW/Pastebin/PastebinCom/Create.pm > README');
}
$builder->create_build_script();
