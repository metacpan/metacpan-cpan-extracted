use Module::Build;

my $build = Module::Build->new(
    module_name => 'WebService::Zaqar',
    dist_abstract => 'SPORE client for Zaqar aka Marconi',
    dist_author => 'Fabrice Gabolde <fgabolde@weborama.com>',
    dist_version_from => 'lib/WebService/Zaqar.pm',
    license => 'gpl',
    configure_requires => {
        'Module::Build' => '0.36_14',
    },
    build_requires => {
        'Test::More' => 0,
        'Test::SetupTeardown' => 0,
    },
    requires => {
        'perl' => '5.10.1',
        'autodie' => 0,
        'Carp' => 0,
        'Data::UUID' => 0,
        'File::ShareDir' => 0,
        'HTTP::Date' => 0,
        'HTTP::Request' => 0,
        'JSON' => 0,
        'List::Util' => 0,
        'Moo' => 0,
        'Net::HTTP::Spore' => 0,
        'Net::HTTP::Spore::Middleware::Header' => 0.03,
        'Scalar::Util' => 0,
        'strict' => 0,
        'Try::Tiny' => 0,
        'URI' => 0,
        'utf8' => 0,
        'warnings' => 0,
    },
    add_to_cleanup => [ 'WebService-Zaqar-*' ],
    share_dir => 'share',
    meta_merge => {
        resources => {
            repository => 'https://github.com/Weborama/WebService-Zaqar.git',
            bugtracker => 'https://github.com/Weborama/WebService-Zaqar/issues',
        },
    },);

$build->create_build_script;
