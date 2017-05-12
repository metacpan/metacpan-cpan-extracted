use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WebService::Kaolabo',
    license             => 'perl',
    dist_author         => 'Akihito Takeda <takeda.akihito@gmail.com>',
    dist_version_from   => 'lib/WebService/Kaolabo.pm',
    requires => {
        'Test::More'         => 0,
        'version'            => 0,
        'Test::Perl::Critic' => 0,
        'Class::Accessor'    => 0,
        'LWP::UserAgent'     => 0,
        'HTTP::Request'      => 0,
        'Data::Average'      => 0,
        'Imager'             => 0,
        'File::Spec'         => 0,
    },
    add_to_cleanup      => [ 'WebService-Kaolabo-*' ],
);

$builder->create_build_script();
