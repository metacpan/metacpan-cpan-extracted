use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name => 'WebService::Basecamp',
    license => 'perl',
    requires => {
        'XML::Simple'    => 0,
        'LWP::UserAgent' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
    dist_author => 'David Baxter <david@sitesuite.com.au>',
    dist_abstract => 'Perl interface to the Basecamp API webservice',
)->create_build_script;
