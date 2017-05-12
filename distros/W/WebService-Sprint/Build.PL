use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'WebService::Sprint',
    license           => 'perl',
    dist_author       => q{Brett T. Warden <bwarden@cpan.org>},
    dist_version_from => 'lib/WebService/Sprint.pm',
    build_requires    => { 'Test::More' => 0, },
    requires          => {
        'DateTime'       => 0,
        'Digest::MD5'    => 0,
        'LWP::Simple'    => 0,
        'LWP::UserAgent' => 0,
        'JSON'           => 0,
        'URI'            => 0,
    },
    add_to_cleanup     => ['WebService-Sprint-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
