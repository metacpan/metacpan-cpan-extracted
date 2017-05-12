use Module::Build;

# See perldoc Module::Build for details of how this works

my $mb = Module::Build->new(
    module_name        => 'WWW::GoDaddy::REST',
    license            => 'mit',
    dist_abstract      => 'Use REST webservices that conform to the GDAPI specification',
    dist_author        => 'David Bartle <davidb@mediatemple.net>',
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    script_files       => { 'script/gdapi-shell' => 'script/gdapi-shell', },
    recommends         => {
        'Config::Tiny'         => 0,    # Config::Any .ini file parsing
        'GraphViz'             => 0,
        'YAML::XS'             => 0,    # Config::Any .yml file parsing
        'LWP::Protocol::https' => 0,
    },
    requires => {
        'Carp'              => 0,
        'Config::Any'       => 0,
        'File::Slurp'       => 0,
        'Getopt::Long'      => 0,
        'HTTP::Request'     => 0,
        'JSON'              => 0,
        'LWP::UserAgent'    => 0,
        'List::MoreUtils'   => 0,
        'List::Util'        => 0,
        'Moose'             => 0,
        'Pod::Usage'        => 0,
        'Term::Shell'       => 0,
        'Text::FormatTable' => 0,
        'Text::Wrap'        => 0,
        'URI'               => 0,
        'URI::QueryParam'   => 0,
    },
    build_requires => {
        'Carp'                      => 0,
        'File::Slurp'               => 0,
        'FindBin'                   => 0,
        'JSON'                      => 0,
        'LWP::UserAgent'            => 0,
        'Test::Exception'           => 0,
        'Test::MockObject'          => 0,
        'Test::MockObject::Extends' => 0,
        'Test::More'                => 0,
    },
    meta_add => {
        resources => {
            license    => 'http://opensource.org/licenses/MIT',
            homepage   => 'https://github.com/godaddy/gdapi-perl',
            repository => 'https://github.com/godaddy/gdapi-perl.git',
            bugtracker => 'https://github.com/godaddy/gdapi-perl/issues'
        },
    },
);
$mb->create_build_script;
