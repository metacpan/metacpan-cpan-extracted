use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::OpenSVN',
    license             => 'mit',
    dist_author         => 'Shlomi Fish',
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    requires =>
    {
        'strict' => 0,
        'LWP::UserAgent' => 0,
        'perl' => "5.006",
        'warnings' => 0,
    },
    build_requires =>
    {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'WWW-OpenSVN-*' ],
    create_makefile_pl => 'traditional',
    meta_add => {
        resources => {
            homepage => "http://web-cpan.berlios.de/modules/WWW-OpenSVN/",
            license => "http://en.wikipedia.org/wiki/MIT_License",
            repository => "https://bitbucket.org/shlomif/perl-www-opensvn",
        },
    },
);

$builder->create_build_script();
