use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Unicode::Escape',
    license             => 'perl',
    dist_author         => 'Hitoshi Amano <seijro@gmail.com>',
    dist_version_from   => 'lib/Unicode/Escape.pm',
    requires => {
        'Test::More' => 0,
        'Encode' => 0,
        'Unicode::String' => 0,
    },
    add_to_cleanup      => [ 'Unicode-Escape-*' ],
);

$builder->create_build_script();
