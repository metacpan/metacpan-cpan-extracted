#!/usr/bin/perl
# Copyright 2010, Bartłomiej Syguła (natanael@natanael.krakow.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://natanael.krakow.pl/
use strict; use warnings;

use Module::Build;
my $build = Module::Build->new (
    # Who I am :)
    module_name => 'Test::FileReferenced',
    license     => 'perl',

    dist_abstract => 'Test against reference data stored in file(s).',
    dist_author   => 'Bartłomiej Syguła <natanael@natanael.krakow.pl>',

    # What You must have, and what will do You good.
    requires => {
        'perl' => '5.8.0',

        'Cwd'            => '3.2701',
        'Test::More'     => '0.94',
        'FindBin'        => '1.47',
        'File::Basename' => '2.74',
        'File::Spec'     => '3.2701',
        'YAML::Any'      => '0.71',
    },
    build_requires => {
        'Test::Exception' => '0.27',
    },

    # Play nice with friends ;)
    create_makefile_pl => 'traditional',
    create_packlist    => 1,
    create_readme      => 1,
    dynamic_config     => 0, # No dynamics needed, as of now.
);

$build->create_build_script;

# vim: fdm=marker
