use strict;
use warnings;
use Module::Build;
my $build = Module::Build->new(
    module_name => 'Time::Piece::Plus',
    dist_author => 'Nishibayashi Takuji <takuji31@gmail.com>',
    license     => 'perl',
    configure_requires => {'Module::Build' => '0.038'},
    requires => {
        'perl'            => '5.010001',
        'Data::Validator' => 0,
        'Mouse'           => 0,
        'Scalar::Util'    => 0,
        'Time::Piece'     => "1.20",
    },
    build_requires => {},
    test_files => (-d '.git/' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    create_readme => 1,
    create_license => 1,
    create_makefile_pl => 'small',
);
$build->create_build_script();
