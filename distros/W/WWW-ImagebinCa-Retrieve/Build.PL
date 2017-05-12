use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::ImagebinCa::Retrieve',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/WWW/ImagebinCa/Retrieve.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                     => 1.04,
        'URI'                      => 1.35,
        'LWP::UserAgent'           => 2.036,
        'File::Spec'               => 3.2701,
        'HTML::TokeParser::Simple' => 3.15,
        'Class::Data::Accessor'    => 0.04001,
    },
    add_to_cleanup      => [ 'WWW-ImagebinCa-Retrieve-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
