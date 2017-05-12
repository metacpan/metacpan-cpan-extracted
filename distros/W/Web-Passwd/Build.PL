use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Web::Passwd',
    license             => 'perl',
    dist_author         => 'Evan Kaufman <evank@cpan.org>',
    dist_version_from   => 'lib/Web/Passwd.pm',
    build_requires => {
        'Test::More' => 0,
        'CGI::Application' => 0,
        'Config::Tiny' => 0,
    },
    add_to_cleanup      => [ 'Web-Passwd-*' ],
);

$builder->create_build_script();
