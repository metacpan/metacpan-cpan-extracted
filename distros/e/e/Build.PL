#!/bin/env perl

use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION( '0.4004' );

sub _readme {
    eval { require Pod::Markdown };
    return if $@;
    print "Building README\n";
    system "pod2markdown lib/e.pm > README.md";
}
_readme();

my $class = Module::Build->subclass(
    code => q{
        sub ACTION_install {
            my ($s) = @_;
            $s->SUPER::ACTION_install;

            # Display logo/image.
            system qq( pod e -q head1=LOGO/Verbatim );
        }
    },
);

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
        'App::Pod'          => '0.38',
        'Data::Printer'     => '0',
        'Data::Trace'       => '1.05',
        'Mojolicious'       => '0',
        'Runtime::Debugger' => '1.03',
        'Sub::Util'         => '0',
        'Term::Table'       => '0',
        'Tiny::Prof'        => '0.03',
        'YAML::XS'          => '0',
    },
    add_to_cleanup => [ 'e-*', 'MANIFEST*.bak', 'blib/', 'pod2htmd.tmp' ],
    meta_merge     => {
        resources => {
            bugtracker => 'https://github.com/poti1/e/issues',
            repository => 'https://github.com/poti1/e',
        },
    },
);

$builder->create_build_script();
