use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WebService::Trynt::PDF',
    license             => 'perl',
    dist_author         => 'Manu <<manu@bjornoya.net>>',
    dist_version_from   => 'lib/WebService/Trynt/PDF.pm',
    build_requires => {
        'Test::More' => 0,
        'LWP::UserAgent' => 0,
        'URI' => 0,
        'File::Copy' => 0,
        'File::Temp' => 0,
        'XML::Simple' => 0,
    },
    add_to_cleanup      => [ 'WebService-Trynt-PDF-*' ],
);

$builder->create_build_script();
