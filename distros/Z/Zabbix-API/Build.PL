use 5.010;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Zabbix::API',
    license             => 'GPL_3',
    dist_author         => [ q{Fabrice Gabolde <fabrice.gabolde@uperto.com>},
                             q{Marc Dequenes <marc.dequenes@uperto.com>} ],
    dist_version_from   => 'lib/Zabbix/API.pm',
    dist_abstract       => 'Access the JSON-RPC API of a Zabbix server',
    configure_requires => { 'Module::Build' => '0.36_14' },
    build_requires => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'File::Spec' => 0
    },
    requires => {
        'perl' => 5.010_001,
        'JSON' => 0,
        'LWP' => 0,
        'Params::Validate' => 0
    },
    add_to_cleanup      => [ 'Zabbix::API-*' ],
    release_status      => 'stable',
    meta_merge          => { resources =>
                             { repository => 'git://github.com/fgabolde/Zabbix-API.git' } },
);

$builder->create_build_script();
