use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::NioTV',
    license             => 'perl',
    dist_author         => 'Alec Chen <alec@cpan.org>',
    dist_version_from   => 'lib/WWW/NioTV.pm',
    build_requires => {
        'Test::More'            => 0.8,
        'WWW::Mechanize'        => 1.34,
        'HTML::TableExtract'    => 2.10,
        'HTML::SimpleLinkExtor' => 1.19,
        'List::MoreUtils'       => 0.22,
        'Moose'                 => 0.54,
        'version'               => 0.76,
    },
    add_to_cleanup      => [ 'WWW-NioTV-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
