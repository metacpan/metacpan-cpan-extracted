use Module::Build;

Module::Build->new(
    module_name => 'Test::WWW::Mechanize::Driver',
    license  => 'unrestricted',
    configure_requires => {
        'Module::Build'  => 0,
    },
    meta_add => {
        resources => {
            homepage => 'https://github.com/duelafn/Test-WWW-Mechanize-Driver',
            repository => 'https://github.com/duelafn/Test-WWW-Mechanize-Driver',
        },
    },
    requires => {
        'perl'                 => '5.5.0',
        'Scalar::Util'         => 0,   # Core from perl 5.8 onward
        'Storable'             => 0,   # Core from perl 5.8 onward
        'Test::Builder'        => 0,   # Core from perl 5.6 onward
        'Test::WWW::Mechanize' => 0,
        'URI'                  => 0,
        'URI::QueryParam'      => 0,
    },
    recommends => {
        'DateTime'             => 0,
        'Template'             => 0,
        'YAML'                 => 0,
    },
    test_requires => {
        'DateTime'             => 0,
        'Template'             => 0,
        'Test::More'           => 0,   # Core from perl 5.6 onward
        'YAML'                 => 0,
    },
)->create_build_script;
