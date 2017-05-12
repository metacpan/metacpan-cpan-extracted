use Module::Build;

use strict;
use warnings;

my $build = Module::Build->new(
    module_name => 'Text::Flow',
    license => 'perl',
    requires => {
         'Moose' => '0.21'
    },
    optional => {
        'Test::PDF' => '0.01',
    },
    build_requires => {
        'Test::More'       => '0.62',
        'Test::Exception'  => '0.21',
        'Test::LongString' => '0',
        'List::Util'       => '0',
    },
    create_makefile_pl => 'traditional',
    recursive_test_files => 1,
    add_to_cleanup => [
        'META.yml', '*.bak', '*.gz', 'Makefile.PL',
    ],
);

$build->create_build_script;

