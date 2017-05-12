use Module::Build;

# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name        => 'WWW::DomainTools',
    license            => 'perl',
    dist_abstract      => 'Interface with domaintools.com XML API',
    dist_author        => 'David Bartle <captindave@gmail.com>',
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    requires           => {
        LWP::UserAgent => 0,
        URI::Escape    => 0,
        XML::Simple    => 0,
    },
    build_requires => {
        Test::Simple   => 0.44,
        LWP::UserAgent => 0,
	HTTP::Request  => 0,
        URI::Escape    => 0,
        XML::Simple    => 0,
        YAML           => 0,
    },
)->create_build_script;
