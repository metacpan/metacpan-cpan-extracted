use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::ASCIIPipe',
    license             => 'perl',
    dist_author         => q{Thomas Orgis <thomas@orgis.org>},
    dist_version_from   => 'lib/Text/ASCIIPipe.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    script_files => [ 'script/asciipipe_in', 'script/asciipipe_out' ],
    add_to_cleanup      => [ 'Text-ASCIIPipe-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
