use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Weather::Bug',
    license             => 'perl',
    dist_author         => 'G. Wade Johnson <wade@anomaly.org>',
    dist_version_from   => 'lib/Weather/Bug.pm',
    requires => {
        'Test::More' => 0,
        'Moose'    => 0,
        'Test::Group' => 0,
        'DateTime'    => 0,
        'DateTime::Format::Builder' => 0,
        'XML::LibXML'    => 0,
        'LWP::Simple' => 0,
        'overload' => 0,
    },
    add_to_cleanup      => [ 'Weather-Bug-*' ],
);

$builder->create_build_script();
