use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Test::JSON',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Test/JSON.pm',
    requires          => {
        'JSON::Any'         => 1.20,
        'Test::Differences' => 0.47,
        'Test::Simple'      => 0.62,
        'Test::Tester'      => 0.107,
    },
    add_to_cleanup     => ['Test-JSON-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
