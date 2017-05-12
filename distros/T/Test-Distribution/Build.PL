use Module::Build;

Module::Build->new(
    license       => 'perl',
    module_name   => 'Test::Distribution',
    requires      => {
        'ExtUtils::Manifest' => 1.43,
        'File::Find::Rule'   => 0.03,
        'Module::CoreList'   => 1.93,
        'Test::More'         => 0.45,
        'Test::Pod'          => 0.95,
        'Test::Pod::Coverage'=> 0,
        'Pod::Coverage'      => 0.17, # Test::Pod::Coverage features that I use need a not very old version of Pod::Coverage. This or 0.15 may be the minimum required.
    },
    create_readme => 1,
    add_to_cleanup       => [ '*.tar.gz', 'Build', '_build' ],
)->create_build_script;
