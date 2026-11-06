use 5.026;
use strict;
use warnings;

use Module::Build;

# The C library's Unicode tables are generated from this perl's Unicode
# database, so they always agree with the perl we are building for.
system($^X, 'scripts/gen_unidata.pl', 'src/unidata.h') == 0
    or die "Could not generate src/unidata.h\n";

my $builder = Module::Build->new(
    module_name => 'Text::BibTeX',
    license     => 'perl',
    dist_author =>
        [ 'Alberto Simões <ambs@cpan.org>', 'Greg Ward <gward@python.net>' ],
    needs_compiler => 1,
    meta_merge     => {
        resources => { repository => 'http://github.com/ambs/Text-BibTeX', },
    },

    # The C library (in src/, derived from Greg Ward's btparse) is compiled
    # straight into the XS module: nothing separate is built or installed.
    c_source     => 'src',
    include_dirs => ['src'],

    configure_requires => {
        'Module::Build' => '0.4004',
    },
    requires => {
        'perl'               => '5.026',
        'Scalar::Util'       => '1.42',
        'Unicode::Normalize' => '0',
        'Encode'             => '0',
    },
    test_requires => {
        'Capture::Tiny' => '0.06',
        'Test::More'    => '0.88',
    },
    add_to_cleanup => [
        'Text-BibTeX-*',
        'src/*.o',
        'src/unidata.h',
    ],
);

$builder->create_build_script;
