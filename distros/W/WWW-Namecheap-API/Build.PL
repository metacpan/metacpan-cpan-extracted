use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Namecheap::API',
    license             => 'perl',
    dist_author         => q{Tim Wilde <twilde@cpan.org>},
    dist_version_from   => 'lib/WWW/Namecheap/API.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Deep' => 0,
    },
    configure_requires => { 'Module::Build' => 0.38 },
    requires => {
        'perl' => 5.006,
        'LWP::UserAgent' => 0,
        'LWP::Protocol::https' => 0,
	'MIME::Base64' => 0,
        'URI::Escape' => 0,
        'XML::Simple' => 0,
    },
    add_to_cleanup      => [ 'WWW-Namecheap-API-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
