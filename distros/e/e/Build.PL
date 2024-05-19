#!/bin/env perl

use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION( '0.4004' );

my $class = Module::Build->subclass(
    code => q{
        sub ACTION_readme {
            my ($s) = @_;
            print "Building README\n";
            system "pod2markdown lib/e.pm > README.md";
        }
        sub ACTION_install {
            my ($s) = @_;
            $s->SUPER::ACTION_install;

            # Display logo/image.
            local @ARGV = (
                "e",
                "-q",
                "head1=LOGO/Verbatim",
            );
            require App::Pod;
            App::Pod->import;
            App::Pod->run;
        }
    },
);
$class->ACTION_readme();

my $builder = $class->new(
    module_name        => 'e',
    license            => 'artistic_2',
    dist_author        => q{Tim Potapov <tim.potapov@gmail.com>},
    dist_version_from  => 'lib/e.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'perl'              => '5.016',
        'Sub::Util'         => '0',
        'Runtime::Debugger' => '1.02',
        'Data::Trace'       => '1.03',
        'Tiny::Prof'        => '0',
        'Mojolicious'       => '0',
        'YAML::XS'          => '0',
        'Data::Printer'     => '0',
        'App::Pod'          => '0.36',
    },
    add_to_cleanup => [ 'e-*', 'MANIFEST*.bak', 'README*', 'blib/' ],
    meta_merge     => {
        resources => {
            bugtracker => 'https://github.com/poti1/e/issues',
            repository => 'https://github.com/poti1/e',
        },
    },
);

$builder->create_build_script();
