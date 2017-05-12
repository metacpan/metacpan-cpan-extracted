use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Purolator::TrackingInfo',
    license             => 'perl',
    dist_author         => q|'Zoffix <'zoffix@cpan.org'>|,
    dist_version_from   => 'lib/WWW/Purolator/TrackingInfo.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::GetVolatileData' => 0,
        'Test::Deep' => 0.112,
    },
    requires => {
        'LWP::UserAgent'           => 6.00,
        'JSON::PP'                 => 2.27203,
        'Class::Accessor::Grouped' => 0.10010,
        perl                    => 5.006,
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'WWW-Purolator-TrackingInfo-*' ],
    create_makefile_pl => 'traditional',
);
if ( $ENV{RELEASE_TESTING} ) {
    system('pod2text lib/WWW/Purolator/TrackingInfo.pm > README');
}
$builder->create_build_script();
