use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'WWW::RobotRules::Memcache',
    license => 'perl',
    dist_author => 'Nick Gerakines <nick@gerakines.net>',
    dist_version_from => 'lib/WWW/RobotRules/Memcache.pm',
    requires => {
        'Cache::Memcached' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    get_options => {
        'memcache'  => { type  => '=s' },
    },
    add_to_cleanup => [ 'WWW-RobotRules-Memcache-*' ],
);

$builder->create_build_script();
