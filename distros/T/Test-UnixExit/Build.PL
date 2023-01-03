#!perl
use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

if ( $^O =~ /MSWin32/ ) {
    print "Windows is not supported\n";
    exit 0;
}

my $builder = Module::Build->new(
    module_name        => 'Test::UnixExit',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Test/UnixExit.pm',
    release_status     => 'stable',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => { 'Test::Most'    => '0', },
    requires           => {
        'Carp'          => '0',
        'Exporter'      => '0',
        'Test::Builder' => '0',
    },
    sign           => 1,
    add_to_cleanup => [ 'Test-UnixExit-*', 'perl.core' ],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge =>
      { resources => { repository => 'https://github.com/thrig/Test-UnixExit' } },
);

$builder->create_build_script;
