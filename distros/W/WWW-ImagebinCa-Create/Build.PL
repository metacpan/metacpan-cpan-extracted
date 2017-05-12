use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::ImagebinCa::Create',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/WWW/ImagebinCa/Create.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                     => 1.04,
        'HTTP::Request::Common'    => 1.28,
        'LWP::UserAgent'           => 2.036,
        'HTML::TokeParser::Simple' => 3.15,
    },
    add_to_cleanup      => [ 'WWW-ImagebinCa-Create-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
