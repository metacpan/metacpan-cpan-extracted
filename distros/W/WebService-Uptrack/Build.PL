use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WebService::Uptrack',
    license             => 'perl',
    dist_author         => 'Steve Huff <shuff@cpan.org>',
    dist_version_from   => 'lib/WebService/Uptrack.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'              => 0,
        'Data::Dumper'      => 0,
        'Moose'             => 0,
        'Moose::Util::TypeConstraints'  => 0,
        'MooseX::StrictConstructor' => 0,
        'HTTP::Request'     => 0,
        'HTTP::Response'    => 0,
        'JSON::XS'          => 0,
        'LWP::UserAgent'    => 0,
        'Readonly'          => 0,
        'version'           => 0,
    },
    add_to_cleanup      => [ 'WebService-Uptrack-*' ],
    meta_merge => {
        resources => {
            repository          => 'https://code.launchpad.net/~shuff/webservice-uptrack/trunk',
        },
    },
    create_makefile_pl      => 'traditional',
);

$builder->create_build_script();
