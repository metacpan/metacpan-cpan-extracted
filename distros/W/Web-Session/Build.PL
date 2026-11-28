use Module::Build;

# See perldoc Module::Build for details of how this works

Module::Build->new(
    dist_author => 'LLNG Team <https://lemonldap-ng.org>',
    module_name => 'Web::Session',
    license     => 'perl',
    requires    => {
        'Apache::Session' => 0,
        'JSON'            => 0,
        'Crypt::URandom'  => 0,
    },
    recommends => {
        'DBI'                 => 0,
        'Net::LDAP'           => 0.44,
        'IO::Socket::Timeout' => 0,
        'Authen::SASL'        => 0,
        'DBD::Cassandra'      => 0,
        'Redis::Fast'         => 0,
    },
    test_requires => {
        DBI           => 0,
        'DBD::SQLite' => 0,
    },
    test_recommends    => { 'LWP::Protocol::PSGI' => 0, },
    dist_version       => '1.0.0',
    autosplit          => [qw(lib/Web/Session/_common.pm)],
    configure_requires => { 'Module::Build' => 0, },
    meta_merge         => {
        resources => {
            repository =>
              'https://github.com/linagora/perl-Web-Session'
        }
    },
)->create_build_script;
