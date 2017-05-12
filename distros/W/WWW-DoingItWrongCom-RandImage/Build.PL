use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::DoingItWrongCom::RandImage',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/WWW/DoingItWrongCom/RandImage.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                     => 1.04,
        'URI'                      => 1.35,
        'LWP::UserAgent'           => 2.036,
        'HTML::TokeParser::Simple' => 3.15,
        'perl' => '5.006',
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'WWW-DoingItWrongCom-RandImage-*' ],
    create_makefile_pl => 'traditional',
);
if ( $ENV{RELEASE_TESTING} ) {
    system('pod2text lib/WWW/DoingItWrongCom/RandImage.pm > README');
}

$builder->create_build_script();
