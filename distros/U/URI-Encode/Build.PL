#!perl

####################
# LOAD MODULES
####################
use strict;
use warnings FATAL => 'all';
use Module::Build;

# Autoflush ON
local $| = 1;

####################
# INIT BUILDER
####################

my $builder = Module::Build->new(
    module_name        => 'URI::Encode',
    license            => 'perl',
    dist_author        => 'Mithun Ayachit <mithun@cpan.org>',
    configure_requires => { 'Module::Build' => 0.38 },
    build_requires     => {
        'Test::More' => 0,
        'version'    => 0,
    },
    requires => {
        'perl'   => '5.8.1',  # for Unicode support
        'Encode' => '2.12',
    },
    add_to_cleanup     => ['URI-Encode-*'],
    create_license     => 1,
    create_makefile_pl => 'traditional',
    meta_merge         => {
        keywords  => [qw(uri escape encode percent)],
        resources => {
            bugtracker => 'https://github.com/mithun/perl-uri-encode/issues',
            repository => 'git://github.com/mithun/perl-uri-encode.git',
            homepage   => 'https://github.com/mithun/perl-uri-encode',
        },
    },
);

####################
# CREATE BUILD SCRIPT
####################
$builder->create_build_script();
