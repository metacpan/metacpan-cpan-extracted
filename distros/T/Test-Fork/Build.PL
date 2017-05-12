#!/usr/bin/perl -w

BEGIN { require 5.006001 }

use Module::Build;

my $build = Module::Build->new(
    module_name     => 'Test::Fork',
    license         => 'perl',
    dist_author     => 'Michael G Schwern <schwern@pobox.com>',

    build_requires  => {
        'Test::More'                => '0.62',
        'Test::Builder::Tester'     => '1.02',
    },

    requires        => {
        'Test::Builder::Module'     => '0.02',
        perl                        => '5.6.1',
    },

    meta_merge => {
        configure_requires => {
            'Module::Build'     => '0.2808'
        },
        resources => {
            license     =>      'http://dev.perl.org/licenses/',
            bugtracker  =>      'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Fork',
            repository  =>      'http://svn.schwern.org/repos/CPAN/Test-Fork',
        }
    },
);

$build->create_build_script;
