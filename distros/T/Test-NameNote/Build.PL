use 5.006001;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Test::NameNote',
    dist_author => 'Nick Cleaton <nick@cleaton.net>',
    all_from    => 'lib/Test/NameNote.pm',
    license     => 'perl',
    requires => {
        'perl'          => 5.006001,
        'Sub::Prepend'  => 0,
        'Test::Builder' => 0,
    },
    build_requires => {
        'File::Slurp'           => 0,
        'File::Temp'            => 0,
        'Test::Builder::Tester' => 0,
        'Test::More'            => 0,
        'Test::Script::Run'     => 0,
    },
    create_makefile_pl => 'traditional',
);
$builder->create_build_script();
