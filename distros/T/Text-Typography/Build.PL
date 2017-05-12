use Module::Build;

Module::Build->new(
    module_name         => 'Text::Typography',
    dist_version        => '0.01',
    dist_author         => 'Thomas Sibley, http://zulutango.org:82/',
    dist_abstract       => 'Markup ASCII text with correct typography for HTML',
    license             => 'unknown',
    build_requires      => { 'Test::More' => 0 },
    create_makefile_pl  => 'traditional',
)->create_build_script;
